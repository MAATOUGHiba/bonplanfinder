import 'restaurant_model.dart';

class NearbyPlacesResult {
  const NearbyPlacesResult({
    required this.restaurants,
    required this.usedCacheFallback,
    this.message,
  });

  final List<RestaurantModel> restaurants;
  final bool usedCacheFallback;
  final String? message;
}
