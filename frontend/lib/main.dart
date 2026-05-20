import 'package:flutter/material.dart';

import 'api_service.dart';
import 'models.dart';
import 'settings_screen.dart';

void main() {
  runApp(const S2AnrufeApp());
}

String gBaseUrl = 'http://192.168.42.43:8777';

class S2AnrufeApp extends StatelessWidget {
  const S2AnrufeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S2Anrufe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _limitController = TextEditingController(text: '10');
  final _searchController = TextEditingController();
  List<Call> _calls = [];
  bool _loading = false;
  String? _error;

  List<Call> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _calls;
    return _calls.where((c) {
      return c.remote.toLowerCase().contains(q) ||
          c.display.toLowerCase().contains(q) ||
          c.searchName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _fetchCalls() async {
    final limit = int.tryParse(_limitController.text.trim()) ?? 10;
    if (limit < 1 || limit > 500) {
      setState(() => _error = 'Limit muss zwischen 1 und 500 liegen.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final calls = await ApiService.fetchRecentCalls(gBaseUrl, limit: limit);
      setState(() {
        _calls = calls;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _limitController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('S2Anrufe'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server-URL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.dns_outlined,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gBaseUrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Abfrage-Zeile
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Anzahl',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _fetchCalls(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _fetchCalls,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Anrufe abrufen'),
                ),
              ],
            ),

            // Fehlermeldung
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(color: cs.onErrorContainer)),
                    ),
                  ],
                ),
              ),
            ],

            // Suchfeld – nur anzeigen wenn Daten vorhanden
            if (_calls.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Suche nach Name oder Nummer…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? '${_calls.length} Anruf${_calls.length == 1 ? '' : 'e'}'
                    : '${filtered.length} von ${_calls.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 16),

            // Liste
            Expanded(
              child: _calls.isEmpty && !_loading && _error == null
                  ? Center(
                      child: Text(
                        'Noch keine Daten abgerufen.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Treffer.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              CallTile(call: filtered[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class CallTile extends StatelessWidget {
  final Call call;
  const CallTile({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child:
            Icon(Icons.phone_outlined, color: cs.onPrimaryContainer, size: 20),
      ),
      title: Text(
        call.display.isNotEmpty ? call.display : call.remote,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            call.remote,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          if (call.searchName.isNotEmpty)
            Text(
              call.searchName,
              style: TextStyle(fontSize: 11, color: cs.primary),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatTs(call.ts),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text('#${call.id}',
              style: TextStyle(fontSize: 11, color: cs.outlineVariant)),
        ],
      ),
    );
  }

  String _formatTs(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final callDay = DateTime(dt.year, dt.month, dt.day);
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (callDay == today) return 'Heute $t';
      if (callDay == today.subtract(const Duration(days: 1)))
        return 'Gestern $t';
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} $t';
    } catch (_) {
      return ts;
    }
  }
}
