import '../config/app_constants.dart';

class RestaurantModel {
  static const String imagePathSeparator = '||';

  const RestaurantModel({
    this.id,
    required this.remoteId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.placeType,
    required this.cuisine,
    required this.phone,
    required this.description,
    required this.imagePath,
    required this.averageRating,
    required this.reviewCount,
    required this.isCached,
    required this.isUserCreated,
    required this.createdBy,
    this.createdByName,
    required this.updatedAt,
  });

  final int? id;
  final String remoteId;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String placeType;
  final String cuisine;
  final String phone;
  final String description;
  final String imagePath;
  final double averageRating;
  final int reviewCount;
  final bool isCached;
  final bool isUserCreated;
  final int? createdBy;
  final String? createdByName;
  final DateTime updatedAt;

  bool get isCafe => placeType.toLowerCase() == 'cafe';
  bool get isRestaurant => placeType.toLowerCase() == 'restaurant';
  bool get hasImage => imagePaths.isNotEmpty;
  bool get hasDescription => description.trim().isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty && phone != 'Not available';
  bool get hasCuisine => cuisine.trim().isNotEmpty && cuisine != placeType;
  List<String> get imagePaths => imagePath
      .split(imagePathSeparator)
      .map((String path) => path.trim())
      .where((String path) => path.isNotEmpty)
      .toList();
  String get primaryImagePath => imagePaths.isEmpty ? '' : imagePaths.first;

  RestaurantModel copyWith({
    int? id,
    String? remoteId,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? placeType,
    String? cuisine,
    String? phone,
    String? description,
    String? imagePath,
    double? averageRating,
    int? reviewCount,
    bool? isCached,
    bool? isUserCreated,
    int? createdBy,
    bool clearCreatedBy = false,
    String? createdByName,
    bool clearCreatedByName = false,
    DateTime? updatedAt,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      placeType: placeType ?? this.placeType,
      cuisine: cuisine ?? this.cuisine,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      isCached: isCached ?? this.isCached,
      isUserCreated: isUserCreated ?? this.isUserCreated,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      createdByName:
          clearCreatedByName ? null : createdByName ?? this.createdByName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'remote_id': remoteId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'place_type': placeType,
      'cuisine': cuisine,
      'phone': phone,
      'description': description,
      'image_path': imagePath,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'is_cached': isCached ? AppConstants.boolTrue : AppConstants.boolFalse,
      'is_user_created':
          isUserCreated ? AppConstants.boolTrue : AppConstants.boolFalse,
      'created_by': createdBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    return RestaurantModel(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      address: map['address'] as String? ?? 'Address unavailable',
      placeType: map['place_type'] as String? ?? AppConstants.restaurantTypeRestaurant,
      cuisine: map['cuisine'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imagePath: map['image_path'] as String? ?? '',
      averageRating: _asDouble(map['average_rating']),
      reviewCount: map['review_count'] as int? ?? AppConstants.defaultReviewCount,
      isCached: (map['is_cached'] as int? ?? AppConstants.boolFalse) ==
          AppConstants.boolTrue,
      isUserCreated:
          (map['is_user_created'] as int? ?? AppConstants.boolFalse) ==
              AppConstants.boolTrue,
      createdBy: map['created_by'] as int?,
      createdByName: map['created_by_name'] as String?,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static double _asDouble(Object? value) {
    return (value as num?)?.toDouble() ?? 0;
  }
}
