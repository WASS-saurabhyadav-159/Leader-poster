class SelfImage {
  final String id;
  final String accountId;
  final int defNum; // Add this field
  final String imageUrl;
  final String imagePath;
  final String position;
  final DateTime createdAt;
  final DateTime updatedAt;

  SelfImage({
    required this.id,
    required this.accountId,
    required this.defNum,
    required this.imageUrl,
    required this.imagePath,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SelfImage.fromJson(Map<String, dynamic> json) {
    return SelfImage(
      id: json['id'],
      accountId: json['accountId'],
      defNum: json['defNum'], // Parse defNum from JSON
      imageUrl: json['image'],
      imagePath: json['imagePath'],
      position: json['position'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}