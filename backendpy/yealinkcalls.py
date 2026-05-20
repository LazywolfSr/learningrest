#!/usr/bin/env python3
"""
Yealink Call Logger (Flask + PostgreSQL + MQTT)

- Empfängt Yealink Action-URLs (incoming.htm, outgoing.htm, ...)
- Speichert Events in PostgreSQL
- Publisht eingehende Anrufe per MQTT im S2Anrufe-Format
- Kleine Web-UI zum Anzeigen und Outbound-Dial über Yealink-CTI

ENV Variablen:
  YCL_PG_DSN=postgresql://yealink:secret@127.0.0.1:5432/senatdb
  YCL_HOST=0.0.0.0
  YCL_PORT=8080
  YCL_PHONE_IP=192.168.42.50
  YCL_PHONE_USER=admin
  YCL_PHONE_PASS=admin

  MQTT_HOST=127.0.0.1
  MQTT_PORT=1883
  MQTT_TOPIC=Calls/Master/home
  MQTT_CLIENT_ID=yealink_bridge
"""

import os
import re
import zoneinfo
import logging
import urllib.parse
from datetime import datetime
from typing import List, Dict, Any, Tuple

import requests
import psycopg
import paho.mqtt.client as mqtt
from psycopg.rows import dict_row
from psycopg.errors import InsufficientPrivilege
from flask import Flask, request, jsonify, send_from_directory, Response, abort

BERLIN = zoneinfo.ZoneInfo("Europe/Berlin")

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

PG_DSN = os.environ.get("YCL_PG_DSN", "")
if not PG_DSN:
    raise SystemExit("YCL_PG_DSN ist nicht gesetzt (z. B. postgresql://user:pass@host:5432/db)")

LISTEN_HOST  = os.environ.get("YCL_HOST",       "0.0.0.0")
LISTEN_PORT  = int(os.environ.get("YCL_PORT",   "8080"))
PHONE_IP     = os.environ.get("YCL_PHONE_IP",   "192.168.42.50")
PHONE_USER   = os.environ.get("YCL_PHONE_USER", "admin")
PHONE_PASS   = os.environ.get("YCL_PHONE_PASS", "admin")

MQTT_HOST      = os.environ.get("MQTT_HOST",      "127.0.0.1")
MQTT_PORT      = int(os.environ.get("MQTT_PORT",  "1883"))
MQTT_TOPIC     = os.environ.get("MQTT_TOPIC",     "Calls/Master/home")
MQTT_CLIENT_ID = os.environ.get("MQTT_CLIENT_ID", "yealink_bridge")

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS calls (
  id         BIGSERIAL PRIMARY KEY,
  ts         TIMESTAMPTZ NOT NULL DEFAULT now(),
  event      TEXT NOT NULL,
  direction  TEXT CHECK(direction IN ('in','out','state','sys')),
  local      TEXT,
  remote     TEXT,
  display    TEXT,
  account    TEXT,
  call_id    TEXT,
  sender_ip  TEXT
);

CREATE INDEX IF NOT EXISTS idx_calls_ts       ON calls(ts DESC);
CREATE INDEX IF NOT EXISTS idx_calls_event    ON calls(event);
CREATE INDEX IF NOT EXISTS idx_calls_callid   ON calls(call_id);
CREATE INDEX IF NOT EXISTS idx_calls_senderip ON calls(sender_ip);
"""

# ---------------------------------------------------------------------------
# DB Helpers
# ---------------------------------------------------------------------------

def get_conn() -> psycopg.Connection:
    return psycopg.connect(PG_DSN, autocommit=True)


def init_db() -> None:
    try:
        with get_conn() as con:
            con.execute(SCHEMA_SQL)
    except Exception as e:
        if isinstance(e, InsufficientPrivilege):
            pass
        else:
            raise


def fmt_ts_for_ui(value: Any) -> str:
    try:
        if isinstance(value, datetime):
            return value.astimezone(BERLIN).strftime("%d.%m.%Y %H:%M:%S")
        if isinstance(value, str):
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return parsed.astimezone(BERLIN).strftime("%d.%m.%Y %H:%M:%S")
    except Exception:
        pass
    return str(value)


def add_row(
    event: str,
    direction: str | None = None,
    *,
    local: str = "",
    remote: str = "",
    display: str = "",
    account: str = "",
    call_id: str = "",
    sender_ip: str = "",
) -> int:
    ts = datetime.now(BERLIN)
    with get_conn() as con:
        with con.cursor() as cur:
            cur.execute(
                """
                INSERT INTO calls (ts, event, direction, local, remote, display, account, call_id, sender_ip)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (ts, event, direction, local, remote, display, account, call_id, sender_ip),
            )
            return cur.fetchone()[0]


def list_calls(limit: int = 200, event_filter: str | None = None) -> List[Dict[str, Any]]:
    sql = "SELECT * FROM calls"
    params: list[Any] = []

    if event_filter:
        sql += " WHERE event = %s"
        params.append(event_filter)

    sql += " ORDER BY id DESC LIMIT %s"
    params.append(limit)

    with get_conn() as con:
        with con.cursor(row_factory=dict_row) as cur:
            cur.execute(sql, params)
            rows = cur.fetchall()
            for r in rows:
                r["ts"] = fmt_ts_for_ui(r.get("ts"))
            return rows


def delete_call(call_id_int: int) -> None:
    with get_conn() as con:
        with con.cursor() as cur:
            cur.execute("DELETE FROM calls WHERE id = %s", (call_id_int,))


# ---------------------------------------------------------------------------
# MQTT
# ---------------------------------------------------------------------------

class MqttPublisher:
    def __init__(self):
        self._client = mqtt.Client(client_id=MQTT_CLIENT_ID)
        self._client.on_connect    = self._on_connect
        self._client.on_disconnect = self._on_disconnect
        self._connected = False

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self._connected = True
            logging.info("MQTT verbunden mit %s:%d", MQTT_HOST, MQTT_PORT)
        else:
            logging.error("MQTT Connect-Fehler rc=%d", rc)

    def _on_disconnect(self, client, userdata, rc):
        self._connected = False
        if rc != 0:
            logging.warning("MQTT unerwartet getrennt (rc=%d), reconnect…", rc)

    def connect(self):
        self._client.reconnect_delay_set(min_delay=2, max_delay=30)
        self._client.connect_async(MQTT_HOST, MQTT_PORT, keepalive=30)
        self._client.loop_start()

    def publish(self, payload: str):
        if not self._connected:
            logging.warning("MQTT nicht verbunden – publish übersprungen")
            return
        result = self._client.publish(MQTT_TOPIC, payload, qos=1, retain=False)
        if result.rc != mqtt.MQTT_ERR_SUCCESS:
            logging.warning("MQTT publish fehlgeschlagen rc=%d", result.rc)
        else:
            logging.info("MQTT → %s  |  %s", MQTT_TOPIC, payload)

    def disconnect(self):
        self._client.loop_stop()
        self._client.disconnect()


_mqtt = MqttPublisher()


def _esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace(",", "\\,")


def _map_status(db_event: str) -> str:
    return {"incoming_call": "1", "outgoing_call": "2"}.get(db_event, "0")


def mqtt_publish_call(db_event: str, remote: str, display: str) -> None:
    """Publisht ein Anruf-Event im S2Anrufe CallEntry-Format."""
    if db_event in ("incoming_call", "outgoing_call"):
        parts = [
            _esc(remote),
            _esc(display),  # search = Anzeigename
            "",             # percent
            datetime.now(BERLIN).strftime("%H:%M:%S"),
            _map_status(db_event),
            "",             # licenseStatus
            "",             # id
            "",             # licenseStatusText
        ]
        _mqtt.publish(",".join(parts))
    elif db_event in ("missed_call", "idle", "hangup"):
        _mqtt.publish("")   # leere Nachricht = Anruf beendet


# ---------------------------------------------------------------------------
# Yealink CTI
# ---------------------------------------------------------------------------

def phone_auth():
    return (PHONE_USER, PHONE_PASS) if (PHONE_USER or PHONE_PASS) else None


def dial_via_phone(number: str) -> Tuple[bool, str]:
    number = (number or "").strip()
    if not number:
        return False, "Leere Nummer"

    enc = urllib.parse.quote(number, safe="")
    url = f"http://{PHONE_IP}/servlet?key=number={enc}"

    try:
        r = requests.get(url, auth=phone_auth(), timeout=4)
        if r.status_code == 200:
            add_row("dial", direction="out", remote=number)
            return True, "Dial gesendet"
        return False, f"Phone Status {r.status_code}"
    except requests.RequestException as e:
        return False, f"Request fehlgeschlagen: {e}"


def hangup_via_phone() -> Tuple[bool, str]:
    try:
        r = requests.get(f"http://{PHONE_IP}/servlet?key=CALLEND", auth=phone_auth(), timeout=4)
        if r.status_code == 200:
            add_row("hangup", direction="state")
            mqtt_publish_call("hangup", "", "")
            return True, "CALLEND gesendet"

        r2 = requests.get(f"http://{PHONE_IP}/servlet?key=ONHOOK", auth=phone_auth(), timeout=4)
        if r2.status_code == 200:
            add_row("hangup", direction="state")
            mqtt_publish_call("hangup", "", "")
            return True, "ONHOOK gesendet"

        return False, f"Phone Status {r.status_code}/{r2.status_code}"
    except requests.RequestException as e:
        return False, f"Request fehlgeschlagen: {e}"


# ---------------------------------------------------------------------------
# Flask
# ---------------------------------------------------------------------------

app = Flask(__name__, static_folder="static")
logging.getLogger("werkzeug").setLevel(logging.ERROR)

STATIC_HTML = r"""<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Yealink Call Logger</title>
  <style>
    body { font-family: -apple-system, system-ui, Segoe UI, Roboto, Helvetica, Arial, sans-serif; margin: 24px; }
    h1 { font-size: 20px; margin: 0 0 16px; }
    .bar { display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
    input[type=text] { flex: 1; min-width: 240px; padding: 10px; border-radius: 10px; border: 1px solid #ccc; font-size: 14px; }
    button, select { padding: 10px 14px; border-radius: 10px; border: 1px solid #bbb; background: #f6f6f6; cursor: pointer; }
    button:hover { background: #eee; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 8px 10px; border-bottom: 1px solid #eee; font-size: 14px; vertical-align: top; }
    th { text-align: left; background: #fafafa; }
    .small { color: #666; font-size: 12px; }
    .row-actions { display: flex; gap: 8px; }
  </style>
</head>
<body>
  <h1>Yealink Call Logger</h1>
  <div class="bar">
    <input id="num" type="text" placeholder="Nummer eingeben oder Strg+V zum Einfügen" />
    <button id="pasteBtn">Einfügen</button>
    <button id="dialBtn">Anrufen</button>
    <button id="hangupBtn">Auflegen</button>
    <select id="filterSelect">
      <option value="incoming">Nur Eingehend</option>
      <option value="all">Alle</option>
    </select>
    <button id="refreshBtn">Aktualisieren</button>
  </div>

  <table>
    <thead>
      <tr>
        <th>#</th>
        <th>Zeit</th>
        <th>Display</th>
        <th>Event</th>
        <th>Richtung</th>
        <th>Local</th>
        <th>Remote</th>
        <th>Account</th>
        <th>Call-ID</th>
        <th>Sender-IP</th>
        <th>Aktionen</th>
      </tr>
    </thead>
    <tbody id="tbody"></tbody>
  </table>

<script>
async function fetchCalls(){
  const filter = document.getElementById('filterSelect').value;
  const url = (filter === 'incoming') ? '/api/incoming' : '/api/calls';
  const res = await fetch(url);
  const data = await res.json();

  const tbody = document.getElementById('tbody');
  tbody.innerHTML = '';

  for(const row of data){
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${row.id}</td>
      <td><span class="small">${row.ts ?? ''}</span></td>
      <td>${row.display ?? ''}</td>
      <td>${row.event ?? ''}</td>
      <td>${row.direction ?? ''}</td>
      <td>${row.local ?? ''}</td>
      <td>${row.remote ?? ''}</td>
      <td>${row.account ?? ''}</td>
      <td>${row.call_id ?? ''}</td>
      <td>${row.sender_ip ?? ''}</td>
      <td class="row-actions">
        <button data-number="${row.remote || row.local || ''}" class="callBtn">Call</button>
        <button data-id="${row.id}" class="delBtn">Löschen</button>
      </td>
    `;
    tbody.appendChild(tr);
  }

  bindRowButtons();
}

function bindRowButtons(){
  document.querySelectorAll('.callBtn').forEach(btn => {
    btn.onclick = async () => {
      const n = btn.getAttribute('data-number');
      if(!n) return alert('Keine Nummer gefunden');
      await dial(n);
    };
  });

  document.querySelectorAll('.delBtn').forEach(btn => {
    btn.onclick = async () => {
      const id = btn.getAttribute('data-id');
      await fetch('/api/calls/' + id, { method: 'DELETE' });
      fetchCalls();
    };
  });
}

async function dial(number){
  const res = await fetch('/api/dial', {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify({ number })
  });
  const js = await res.json();
  if(!js.ok) alert(js.message || 'Dial fehlgeschlagen');
  else fetchCalls();
}

const num = document.getElementById('num');
const pasteBtn = document.getElementById('pasteBtn');
const dialBtn = document.getElementById('dialBtn');
const hangupBtn = document.getElementById('hangupBtn');
const refreshBtn = document.getElementById('refreshBtn');
const filterSelect = document.getElementById('filterSelect');

pasteBtn.onclick = async () => {
  try {
    const t = await navigator.clipboard.readText();
    num.value = (t || '').replace(/\D+/g, '');
  } catch(e) {
    alert('Clipboard nicht erlaubt. Bitte ins Feld einfügen.');
    num.focus();
  }
};

dialBtn.onclick = async () => {
  const n = num.value.trim();
  if(!n) return alert('Bitte Nummer eingeben');
  await dial(n);
};

hangupBtn.onclick = async () => {
  const res = await fetch('/api/hangup', { method: 'POST' });
  const js = await res.json();
  if(!js.ok) alert(js.message || 'Auflegen fehlgeschlagen');
  else fetchCalls();
};

refreshBtn.onclick = fetchCalls;
filterSelect.onchange = fetchCalls;

fetchCalls();
setInterval(fetchCalls, 5000);
</script>
</body>
</html>
"""


def ensure_static() -> None:
    os.makedirs("static", exist_ok=True)
    idx = os.path.join("static", "index.html")
    if not os.path.exists(idx):
        with open(idx, "w", encoding="utf-8") as f:
            f.write(STATIC_HTML)


@app.route("/")
def index() -> Response:
    ensure_static()
    return send_from_directory("static", "index.html")


@app.route("/health")
def health() -> Response:
    return jsonify({"ok": True, "time": datetime.now(BERLIN).strftime("%d.%m.%Y %H:%M:%S")})


@app.route("/api/calls")
def api_calls() -> Response:
    return jsonify(list_calls())


@app.route("/api/incoming")
def api_incoming() -> Response:
    return jsonify(list_calls(event_filter="incoming_call"))


@app.route("/api/calls/<int:call_id>", methods=["DELETE"])
def api_delete_call(call_id: int) -> Response:
    delete_call(call_id)
    return ("", 204)


@app.route("/api/dial", methods=["POST"])
def api_dial() -> Response:
    data = request.get_json(force=True, silent=True) or {}
    number = str(data.get("number", "")).strip()
    ok, msg = dial_via_phone(number)
    return jsonify({"ok": ok, "message": msg}), (200 if ok else 400)


@app.route("/api/hangup", methods=["POST"])
def api_hangup() -> Response:
    ok, msg = hangup_via_phone()
    return jsonify({"ok": ok, "message": msg}), (200 if ok else 400)


HTM_RE = re.compile(r"^/(?P<name>[A-Za-z0-9_]+)\.htm$")


@app.route("/<path:path>")
def catch_all(path: str) -> Response:
    m = HTM_RE.match("/" + path)
    if not m:
        abort(404)
    return _save_event(m.group("name"))


def _save_event(event_name: str) -> Response:
    local      = request.args.get("local",          request.args.get("to",    ""))
    remote     = request.args.get("remote",         request.args.get("from",  ""))
    display    = request.args.get("display_remote", request.args.get("disp",  ""))
    account    = request.args.get("account",        request.args.get("acct",  ""))
    call_id    = request.args.get("call_id",        request.args.get("callid",""))
    sender_ip  = request.args.get("sender_ip", "")

    if event_name in ("incoming", "incoming_call", "answer_new_incoming_call", "answ_new_incall"):
        db_event  = "incoming_call"
        direction = "in"
    elif event_name in ("outgoing", "outgoing_call"):
        db_event  = "outgoing_call"
        direction = "out"
    elif event_name in ("missed_call",):
        db_event  = "missed_call"
        direction = "in"
    elif event_name in ("idle", "callend", "onhook"):
        db_event  = "idle"
        direction = "state"
    else:
        db_event  = event_name
        direction = "state"

    add_row(
        db_event,
        direction=direction,
        local=local,
        remote=remote,
        display=display,
        account=account,
        call_id=call_id,
        sender_ip=sender_ip,
    )

    mqtt_publish_call(db_event, remote, display)

    now_str = datetime.now(BERLIN).strftime("%d.%m.%Y %H:%M:%S")
    who = display or remote or "(unbekannt)"
    print(f"[{now_str}] {db_event}: {who}")

    return ("OK", 200)


@app.after_request
def silence_calls(response):
    path = request.path or ""
    if response.status_code == 200 and (
        path.startswith("/api/calls")
        or path.startswith("/api/incoming")
        or path == "/health"
    ):
        logging.getLogger("werkzeug").disabled = True
    else:
        logging.getLogger("werkzeug").disabled = False
    return response


if __name__ == "__main__":
    init_db()
    ensure_static()
    _mqtt.connect()
    print(f"PostgreSQL: {PG_DSN}")
    print(f"MQTT:       {MQTT_HOST}:{MQTT_PORT} → {MQTT_TOPIC}")
    print(f"Serving on  http://{LISTEN_HOST}:{LISTEN_PORT}")
    try:
        app.run(host=LISTEN_HOST, port=LISTEN_PORT, debug=False)
    finally:
        _mqtt.disconnect()
