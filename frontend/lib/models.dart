class Call {
  final int id;
  final String ts;
  final String remote;
  final String display;
  final String searchName;

  const Call({
    required this.id,
    required this.ts,
    required this.remote,
    required this.display,
    required this.searchName,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as int? ?? 0,
      ts: json['ts'] as String? ?? '',
      remote: json['remote'] as String? ?? '',
      display: json['display'] as String? ?? '',
      searchName: json['search_name'] as String? ?? '',
    );
  }
}
