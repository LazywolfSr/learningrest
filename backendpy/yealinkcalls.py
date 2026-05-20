#!/usr/bin/env python3
import os
import re
import zoneinfo
import logging
import urllib.parse
from datetime import datetime
from typing import Any, Dict, List, Tuple, Optional

import requests
import psycopg
import paho.mqtt.client as mqtt
from psycopg.rows import dict_row
from psycopg.errors import InsufficientPrivilege

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, PlainTextResponse
from pydantic import BaseModel

BERLIN = zoneinfo.ZoneInfo("Europe/Berlin")

PG_DSN = os.environ.get("YCL_PG_DSN", "")
if not PG_DSN:
    raise SystemExit("YCL_PG_DSN ist nicht gesetzt")

LISTEN_HOST = os.environ.get("YCL_HOST", "0.0.0.0")
LISTEN_PORT = int(os.environ.get("YCL_PORT", "8080"))

PHONE_IP = os.environ.get("YCL_PHONE_IP", "192.168.42.50")
PHONE_USER = os.environ.get("YCL_PHONE_USER", "admin")
PHONE_PASS = os.environ.get("YCL_PHONE_PASS", "admin")

MQTT_HOST = os.environ.get("MQTT_HOST", "127.0.0.1")
MQTT_PORT = int(os.environ.get("MQTT_PORT", "1883"))
MQTT_TOPIC = os.environ.get("MQTT_TOPIC", "Calls/Master/home")
MQTT_CLIENT_ID = os.environ.get("MQTT_CLIENT_ID", "yealink_bridge")


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


def get_conn() -> psycopg.Connection:
    return psycopg.connect(PG_DSN, autocommit=True)


def init_db() -> None:
    try:
        with get_conn() as con:
            con.execute(SCHEMA_SQL)
    except Exception as e:
        if not isinstance(e, InsufficientPrivilege):
            raise


def fmt_ts_for_ui(value: Any) -> str:
    try:
        if isinstance(value, datetime):
            return value.astimezone(BERLIN).strftime("%d.%m.%Y %H:%M:%S")
    except Exception:
        pass
    return str(value)


def add_row(
    event: str,
    direction: Optional[str] = None,
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
                INSERT INTO calls
                  (ts, event, direction, local, remote, display, account, call_id, sender_ip)
                VALUES
                  (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    ts,
                    event,
                    direction,
                    local,
                    remote,
                    display,
                    account,
                    call_id,
                    sender_ip,
                ),
            )
            return cur.fetchone()[0]


def list_calls(
    limit: int = 200, event_filter: Optional[str] = None
) -> List[Dict[str, Any]]:
    limit = max(1, min(limit, 500))

    sql = "SELECT * FROM calls"
    params: list[Any] = []

    if event_filter:
        sql += " WHERE event = %s"
        params.append(event_filter)

    sql += " ORDER BY ts DESC LIMIT %s"
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


class MqttPublisher:
    def __init__(self):
        self._client = mqtt.Client(client_id=MQTT_CLIENT_ID)
        self._client.on_connect = self._on_connect
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
            logging.warning("MQTT unerwartet getrennt rc=%d", rc)

    def connect(self):
        self._client.reconnect_delay_set(min_delay=2, max_delay=30)
        self._client.connect_async(MQTT_HOST, MQTT_PORT, keepalive=30)
        self._client.loop_start()

    def publish(self, payload: str):
        if not self._connected:
            logging.warning("MQTT nicht verbunden – publish übersprungen")
            return

        self._client.publish(MQTT_TOPIC, payload, qos=1, retain=False)

    def disconnect(self):
        self._client.loop_stop()
        self._client.disconnect()


_mqtt = MqttPublisher()


def _esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace(",", "\\,")


def _map_status(db_event: str) -> str:
    return {
        "incoming_call": "1",
        "outgoing_call": "2",
    }.get(db_event, "0")


def mqtt_publish_call(db_event: str, remote: str, display: str) -> None:
    if db_event in ("incoming_call", "outgoing_call"):
        parts = [
            _esc(remote),
            _esc(display),
            "",
            datetime.now(BERLIN).strftime("%H:%M:%S"),
            _map_status(db_event),
            "",
            "",
            "",
        ]
        _mqtt.publish(",".join(parts))

    elif db_event in ("missed_call", "idle", "hangup"):
        _mqtt.publish("")


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
        r = requests.get(
            f"http://{PHONE_IP}/servlet?key=CALLEND", auth=phone_auth(), timeout=4
        )

        if r.status_code == 200:
            add_row("hangup", direction="state")
            mqtt_publish_call("hangup", "", "")
            return True, "CALLEND gesendet"

        r2 = requests.get(
            f"http://{PHONE_IP}/servlet?key=ONHOOK", auth=phone_auth(), timeout=4
        )

        if r2.status_code == 200:
            add_row("hangup", direction="state")
            mqtt_publish_call("hangup", "", "")
            return True, "ONHOOK gesendet"

        return False, f"Phone Status {r.status_code}/{r2.status_code}"

    except requests.RequestException as e:
        return False, f"Request fehlgeschlagen: {e}"


class DialRequest(BaseModel):
    number: str


app = FastAPI(
    title="Yealink Call Logger",
    version="1.0.0",
)


@app.on_event("startup")
def startup_event():
    init_db()
    _mqtt.connect()
    print(f"PostgreSQL: {PG_DSN}")
    print(f"MQTT:       {MQTT_HOST}:{MQTT_PORT} → {MQTT_TOPIC}")
    print(f"Swagger:    http://{LISTEN_HOST}:{LISTEN_PORT}/docs")


@app.on_event("shutdown")
def shutdown_event():
    _mqtt.disconnect()


@app.get("/health")
def health():
    return {
        "ok": True,
        "time": datetime.now(BERLIN).strftime("%d.%m.%Y %H:%M:%S"),
    }


@app.get("/api/v1/calls/recent")
def api_v1_calls_recent(limit: int = 10):
    return list_calls(limit=limit)


@app.get("/api/calls")
def api_calls(limit: int = 200):
    return list_calls(limit=limit)


@app.get("/api/incoming")
def api_incoming(limit: int = 200):
    return list_calls(limit=limit, event_filter="incoming_call")


@app.delete("/api/calls/{call_id}", status_code=204)
def api_delete_call(call_id: int):
    delete_call(call_id)
    return None


@app.post("/api/dial")
def api_dial(data: DialRequest):
    ok, msg = dial_via_phone(data.number)

    if not ok:
        raise HTTPException(status_code=400, detail=msg)

    return {
        "ok": True,
        "message": msg,
    }


@app.post("/api/hangup")
def api_hangup():
    ok, msg = hangup_via_phone()

    if not ok:
        raise HTTPException(status_code=400, detail=msg)

    return {
        "ok": True,
        "message": msg,
    }


HTML = """<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Yealink Call Logger</title>
</head>
<body>
  <h1>Yealink Call Logger</h1>
  <p><a href="/docs">Swagger / OpenAPI</a></p>
  <p><a href="/api/v1/calls/recent?limit=10">Letzte 10 Anrufe</a></p>
</body>
</html>
"""


@app.get("/", response_class=HTMLResponse)
def index():
    return HTML


HTM_RE = re.compile(r"^(?P<name>[A-Za-z0-9_]+)\.htm$")


@app.get("/{path:path}")
def catch_all(path: str, request: Request):
    m = HTM_RE.match(path)

    if not m:
        raise HTTPException(status_code=404, detail="Not found")

    return save_event(m.group("name"), request)


def save_event(event_name: str, request: Request):
    q = request.query_params

    local = q.get("local", q.get("to", ""))
    remote = q.get("remote", q.get("from", ""))
    display = q.get("display_remote", q.get("disp", ""))
    account = q.get("account", q.get("acct", ""))
    call_id = q.get("call_id", q.get("callid", ""))
    sender_ip = q.get("sender_ip", "")

    if event_name in (
        "incoming",
        "incoming_call",
        "answer_new_incoming_call",
        "answ_new_incall",
    ):
        db_event = "incoming_call"
        direction = "in"
    elif event_name in ("outgoing", "outgoing_call"):
        db_event = "outgoing_call"
        direction = "out"
    elif event_name in ("missed_call",):
        db_event = "missed_call"
        direction = "in"
    elif event_name in ("idle", "callend", "onhook"):
        db_event = "idle"
        direction = "state"
    else:
        db_event = event_name
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

    return PlainTextResponse("OK")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=LISTEN_HOST,
        port=LISTEN_PORT,
    )
