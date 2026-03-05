class SelfImage {
  final String id;
  final String accountId;
  final int defNum;
  final String imageUrl;
  final String imagePath;
  final String position;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  SelfImage({
    required this.id,
    required this.accountId,
    required this.defNum,
    required this.imageUrl,
    required this.imagePath,
    required this.position,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SelfImage.fromJson(Map<String, dynamic> json) {
    return SelfImage(
      id: json['id'],
      accountId: json['accountId'],
      defNum: json['defNum'] ?? 0,
      imageUrl: json['image'],
      imagePath: json['imagePath'],
      position: json['position'],
      uploadedBy: json['uploadedBy'] ?? 'ADMIN',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}