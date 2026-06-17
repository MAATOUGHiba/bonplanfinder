import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_constants.dart';
import '../models/nearby_places_result.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  static const int nearbyPreviewLimit = 10;

  RestaurantProvider({RestaurantService? restaurantService})
      : _restaurantService = restaurantService ?? RestaurantService();

  final RestaurantService _restaurantService;

  List<RestaurantModel> _restaurants = <RestaurantModel>[];
  List<RestaurantModel> _communityPicks = <RestaurantModel>[];
  List<RestaurantModel> _myPlaces = <RestaurantModel>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _usedCacheFallback = false;
  String _searchQuery = '';
  double? _currentLatitude;
  double? _currentLongitude;

  List<RestaurantModel> get restaurants {
    final List<RestaurantModel> nearbyOnly = _restaurants
        .where((RestaurantModel restaurant) => !restaurant.isUserCreated)
        .toList();
    final List<RestaurantModel> filtered = _applySearch(nearbyOnly);
    return _sortByDistance(filtered);
  }
  List<RestaurantModel> get nearbyPreviewRestaurants {
    if (_searchQuery.trim().isNotEmpty) {
      // Keep search results complete so users can search beyond the first 10 cards.
      return restaurants;
    }
    return restaurants.take(nearbyPreviewLimit).toList();
  }
  List<RestaurantModel> get allRestaurants => _restaurants;
  List<RestaurantModel> get communityPicks => _communityPicks;
  List<RestaurantModel> get myPlaces => _myPlaces;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  bool get usedCacheFallback => _usedCacheFallback;
  String get searchQuery => _searchQuery;
  bool get hasActiveSearch => _searchQuery.trim().isNotEmpty;
  bool get hasMoreNearbyResults =>
      !hasActiveSearch && restaurants.length > nearbyPreviewLimit;

  Future<void> loadNearbyRestaurants({
    required double latitude,
    required double longitude,
    int? userId,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    _usedCacheFallback = false;
    notifyListeners();

    try {
      debugPrint(
        'RestaurantProvider.loadNearbyRestaurants -> lat=$latitude, lng=$longitude',
      );
      _currentLatitude = latitude;
      _currentLongitude = longitude;
      final NearbyPlacesResult result =
          await _restaurantService.getNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        forceRefresh: forceRefresh,
      );
      _restaurants = result.restaurants;
      _usedCacheFallback = result.usedCacheFallback;
      _infoMessage = result.message;
      debugPrint(
        'RestaurantProvider -> restaurants loaded: ${_restaurants.length}',
      );
      await _loadSecondaryCollections(userId: userId);
    } catch (e) {
      debugPrint('RestaurantProvider -> error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCommunityData({int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      _restaurants = await _restaurantService.getCachedRestaurants();
      await _loadSecondaryCollections(userId: userId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRestaurant(int restaurantId, {int? userId}) async {
    try {
      final RestaurantModel? restaurant =
          await _restaurantService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        return;
      }

      final int index =
          _restaurants.indexWhere((RestaurantModel item) => item.id == restaurantId);
      if (index != -1) {
        _restaurants[index] = restaurant;
      } else {
        _restaurants.add(restaurant);
      }

      _upsertCollection(_communityPicks, restaurant);
      _upsertCollection(_myPlaces, restaurant);
      if (userId != null) {
        await _loadSecondaryCollections(userId: userId);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addPlace({
    required int userId,
    required String name,
    required String address,
    required String placeType,
    required String description,
    required String cuisine,
    required String phone,
    required String imagePath,
    required double latitude,
    required double longitude,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RestaurantModel created = await _restaurantService.addUserPlace(
        userId: userId,
        restaurant: RestaurantModel(
          remoteId: '',
          name: name.trim(),
          latitude: latitude,
          longitude: longitude,
          address: address.trim(),
          placeType: placeType,
          cuisine: cuisine.trim(),
          phone: phone.trim(),
          description: description.trim(),
          imagePath: imagePath.trim(),
          averageRating: AppConstants.defaultRating,
          reviewCount: AppConstants.defaultReviewCount,
          isCached: true,
          isUserCreated: true,
          createdBy: userId,
          updatedAt: DateTime.now(),
        ),
      );

      _restaurants = <RestaurantModel>[created, ..._restaurants];
      _communityPicks = <RestaurantModel>[created, ..._communityPicks];
      _myPlaces = <RestaurantModel>[created, ..._myPlaces];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlace({
    required int userId,
    required RestaurantModel restaurant,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RestaurantModel updated = await _restaurantService.updateUserPlace(
        userId: userId,
        restaurant: restaurant,
      );
      _replaceRestaurant(updated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deletePlace({
    required int userId,
    required int restaurantId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _restaurantService.deleteUserPlace(
        userId: userId,
        restaurantId: restaurantId,
      );
      _restaurants.removeWhere((RestaurantModel item) => item.id == restaurantId);
      _communityPicks.removeWhere(
        (RestaurantModel item) => item.id == restaurantId,
      );
      _myPlaces.removeWhere((RestaurantModel item) => item.id == restaurantId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearInfoMessage() {
    _infoMessage = null;
    notifyListeners();
  }

  List<RestaurantModel> _sortByDistance(List<RestaurantModel> source) {
    if (_currentLatitude == null || _currentLongitude == null) {
      return source;
    }

    final List<RestaurantModel> sorted = List<RestaurantModel>.from(source);
    sorted.sort((RestaurantModel a, RestaurantModel b) {
      final double distanceA = Geolocator.distanceBetween(
        _currentLatitude!,
        _currentLongitude!,
        a.latitude,
        a.longitude,
      );
      final double distanceB = Geolocator.distanceBetween(
        _currentLatitude!,
        _currentLongitude!,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    return sorted;
  }

  List<RestaurantModel> _applySearch(List<RestaurantModel> source) {
    if (_searchQuery.trim().isEmpty) {
      return source;
    }

    final String query = _searchQuery.trim().toLowerCase();
    return source.where((RestaurantModel restaurant) {
      return restaurant.name.toLowerCase().contains(query) ||
          restaurant.address.toLowerCase().contains(query) ||
          restaurant.cuisine.toLowerCase().contains(query) ||
          restaurant.placeType.toLowerCase().contains(query) ||
          restaurant.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadSecondaryCollections({int? userId}) async {
    _communityPicks = await _restaurantService.getCommunityPlaces();
    _myPlaces = userId == null
        ? <RestaurantModel>[]
        : await _restaurantService.getPlacesCreatedByUser(userId);
  }

  void _replaceRestaurant(RestaurantModel restaurant) {
    final int allIndex =
        _restaurants.indexWhere((RestaurantModel item) => item.id == restaurant.id);
    if (allIndex == -1) {
      _restaurants = <RestaurantModel>[restaurant, ..._restaurants];
    } else {
      _restaurants[allIndex] = restaurant;
    }

    _upsertCollection(_communityPicks, restaurant);
    _upsertCollection(_myPlaces, restaurant);
    notifyListeners();
  }

  void _upsertCollection(
    List<RestaurantModel> collection,
    RestaurantModel restaurant,
  ) {
    final int index =
        collection.indexWhere((RestaurantModel item) => item.id == restaurant.id);
    if (index == -1) {
      if (restaurant.isUserCreated) {
        collection.insert(0, restaurant);
      }
      return;
    }

    if (!restaurant.isUserCreated) {
      collection.removeAt(index);
      return;
    }

    collection[index] = restaurant;
  }
}
