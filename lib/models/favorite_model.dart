class FavoriteModel {
  const FavoriteModel({
    this.id,
    required this.userId,
    required this.restaurantId,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final int restaurantId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      restaurantId: map['restaurant_id'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
