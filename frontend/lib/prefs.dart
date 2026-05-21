import 'dart:convert';
import 'dart:io';

/// Minimaler persistenter Key-Value-Store.
/// Speichert als JSON in ~/Library/Application Support/s2anrufe/prefs.json (macOS)
/// bzw. ~/.config/s2anrufe/prefs.json (Linux).
class Prefs {
  static final Map<String, String> _cache = {};
  static bool _loaded = false;

  static File _file() {
    final home = Platform.environment['HOME'] ?? '.';
    final String dir;
    if (Platform.isMacOS) {
      dir = '$home/Library/Application Support/s2anrufe';
    } else {
      dir = '$home/.config/s2anrufe';
    }
    Directory(dir).createSync(recursive: true);
    return File('$dir/prefs.json');
  }

  static Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = _file();
      if (!f.existsSync()) return;
      final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      map.forEach((k, v) => _cache[k] = v.toString());
    } catch (_) {}
  }

  static Future<void> _save() async {
    try {
      await _file().writeAsString(jsonEncode(_cache));
    } catch (_) {}
  }

  static Future<String?> get(String key) async {
    await _load();
    return _cache[key];
  }

  static Future<void> set(String key, String value) async {
    await _load();
    _cache[key] = value;
    await _save();
  }
}
