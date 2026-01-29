class FooterImage {
  final String id;
  final String accountId;
  final int defNum; // Add this field
  final String imageUrl;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocal; // Local image flag

  FooterImage({
    required this.id,
    required this.accountId,
    required this.defNum,
    required this.imageUrl,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isLocal = false, // Default to false for API images
  });

  factory FooterImage.fromJson(Map<String, dynamic> json) {
    return FooterImage(
      id: json['id'],
      accountId: json['accountId'],
      defNum: json['defNum'], // Parse defNum from JSON
      imageUrl: json['image'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isLocal: false, // API images are not local
    );
  }

  // Factory constructor for local images
  factory FooterImage.local(String path) {
    return FooterImage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      accountId: 'local',
      defNum: 0, // Default value for local images
      imageUrl: path,
      imagePath: path,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isLocal: true,
    );
  }

  // Optional: Add a method to convert to JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'defNum': defNum,
      'image': imageUrl,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLocal': isLocal,
    };
  }

  // Optional: Add copyWith method for easier updates
  FooterImage copyWith({
    String? id,
    String? accountId,
    int? defNum,
    String? imageUrl,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocal,
  }) {
    return FooterImage(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      defNum: defNum ?? this.defNum,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}