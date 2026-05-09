class Major {
  final String id;
  final String name;
  final List<String> prodiList;

  Major({
    required this.id,
    required this.name,
    this.prodiList = const [],
  });

  factory Major.fromJson(Map<String, dynamic> json, String id) {
    return Major(
      id: id,
      name: json['name'] ?? '',
      prodiList: List<String>.from(json['prodiList'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'prodiList': prodiList,
    };
  }
}
