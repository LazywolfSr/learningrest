class Call {
  final int id;
  final String ts;
  final String remote;
  final String display;

  const Call({
    required this.id,
    required this.ts,
    required this.remote,
    required this.display,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as int? ?? 0,
      ts: json['ts'] as String? ?? '',
      remote: json['remote'] as String? ?? '',
      display: json['display'] as String? ?? '',
    );
  }

  @override
  String toString() => 'Call(id: $id, remote: $remote, display: $display)';
}
