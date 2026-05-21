import 'package:flutter/material.dart';
import 'main.dart' show gBaseUrl;
import 'prefs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: gBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validate(String url) {
    if (url.trim().isEmpty) return 'URL darf nicht leer sein.';
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.scheme.startsWith('http')) {
      return 'Bitte eine gültige URL eingeben (http:// oder https://).';
    }
    return null;
  }

  void _save() {
    final url = _urlController.text.trim();
    final error = _validate(url);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    gBaseUrl = url;
    Prefs.set('base_url', url);
    Navigator.pop(context);
  }

  void _reset() {
    _urlController.text = 'http://192.168.42.48:8777';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REST-Server',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Basis-URL des Servers inkl. Port, ohne abschließenden Slash.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Server-URL',
                hintText: 'http://192.168.42.48:8777',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Standard wiederherstellen'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
