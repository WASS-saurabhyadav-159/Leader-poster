class ProtocolImage {
  final String id;
  final String accountId;
  final int defNum; // Add this field
  final String imageUrl;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProtocolImage({
    required this.id,
    required this.accountId,
    required this.defNum, // Include in constructor
    required this.imageUrl,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProtocolImage.fromJson(Map<String, dynamic> json) {
    return ProtocolImage(
      id: json['id'],
      accountId: json['accountId'],
      defNum: json['defNum'], // Parse defNum from JSON
      imageUrl: json['image'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}