import 'package:flutter/foundation.dart';

import '../models/favorite_model.dart';
import '../models/restaurant_model.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesService? favoritesService})
      : _favoritesService = favoritesService ?? FavoritesService();

  final FavoritesService _favoritesService;

  List<RestaurantModel> _favoriteRestaurants = <RestaurantModel>[];
  Set<int> _favoriteIds = <int>{};
  bool _isLoading = false;
  String? _errorMessage;

  List<RestaurantModel> get favoriteRestaurants => _favoriteRestaurants;
  Set<int> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFavorites(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favoriteRestaurants =
          await _favoritesService.getFavoriteRestaurantsByUser(userId);
      _favoriteIds = _favoriteRestaurants
          .map((RestaurantModel restaurant) => restaurant.id)
          .whereType<int>()
          .toSet();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavoriteLocal(int restaurantId) {
    return _favoriteIds.contains(restaurantId);
  }

  Future<bool> isFavorite({
    required int userId,
    required int restaurantId,
  }) async {
    try {
      if (_favoriteIds.contains(restaurantId)) {
        return true;
      }
      final bool favorite = await _favoritesService.isFavorite(
        userId: userId,
        restaurantId: restaurantId,
      );
      if (favorite) {
        _favoriteIds = <int>{..._favoriteIds, restaurantId};
        notifyListeners();
      }
      return favorite;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite({
    required int userId,
    required int restaurantId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool favorite = await _favoritesService.isFavorite(
        userId: userId,
        restaurantId: restaurantId,
      );

      if (favorite) {
        await _favoritesService.removeFavorite(
          userId: userId,
          restaurantId: restaurantId,
        );
      } else {
        await _favoritesService.addFavorite(
          FavoriteModel(
            userId: userId,
            restaurantId: restaurantId,
            createdAt: DateTime.now(),
          ),
        );
      }

      await loadFavorites(userId);
      return !favorite;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
