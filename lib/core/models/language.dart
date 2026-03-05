class Language {
  final String id;
  final String name;

  Language({
    required this.id,
    required this.name,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
