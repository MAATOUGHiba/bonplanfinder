import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import '../config/app_constants.dart';
import '../models/nearby_places_result.dart';
import '../models/restaurant_model.dart';
import 'api_service.dart';
import 'database_service.dart';

class RestaurantService {
  RestaurantService({
    DatabaseService? databaseService,
    ApiService? apiService,
  })  : _databaseService = databaseService ?? DatabaseService.instance,
        _apiService = apiService ?? const ApiService();

  final DatabaseService _databaseService;
  final ApiService _apiService;

  Future<NearbyPlacesResult> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint(
        'RestaurantService.getNearbyRestaurants -> forceRefresh=$forceRefresh',
      );

      if (!forceRefresh) {
        final List<RestaurantModel> cachedRestaurants =
            await getCachedRestaurants();
        if (_hasValidCache(cachedRestaurants)) {
          debugPrint(
            'RestaurantService -> Returning valid cached restaurants: ${cachedRestaurants.length}',
          );
          return NearbyPlacesResult(
            restaurants: cachedRestaurants,
            usedCacheFallback: false,
          );
        }
      }

      final List<RestaurantModel> restaurants =
          await _apiService.fetchNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
      );

      debugPrint(
        'RestaurantService -> API returned ${restaurants.length} places.',
      );

      await _saveNearbyRestaurants(restaurants);
      return NearbyPlacesResult(
        restaurants: await getCachedRestaurants(),
        usedCacheFallback: false,
      );
    } catch (e) {
      debugPrint('RestaurantService -> fetch error: $e');
      final List<RestaurantModel> cachedRestaurants = await getCachedRestaurants();
      final String errorMessage = e.toString();
      final bool shouldUseCache = cachedRestaurants.isNotEmpty &&
          !forceRefresh &&
          (errorMessage.contains(AppConstants.internetUnavailableMessage) ||
              errorMessage.contains(AppConstants.timeoutErrorMessage) ||
              errorMessage.contains('Unable to load nearby places right now.') ||
              errorMessage.contains('Received an invalid response'));

      if (shouldUseCache) {
        debugPrint(
          'RestaurantService -> Falling back to cache: ${cachedRestaurants.length}',
        );
        return NearbyPlacesResult(
          restaurants: cachedRestaurants,
          usedCacheFallback: true,
          message: AppConstants.cacheFallbackMessage,
        );
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unable to load nearby restaurants.');
    }
  }

  Future<List<RestaurantModel>> getCachedRestaurants() async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        '''
        SELECT r.*, u.name AS created_by_name
        FROM ${AppConstants.restaurantsTable} r
        LEFT JOIN ${AppConstants.usersTable} u
          ON u.id = r.created_by
        ORDER BY
          r.is_user_created DESC,
          r.average_rating DESC,
          r.review_count DESC,
          r.name ASC
        ''',
      );
      return result
          .map((Map<String, Object?> map) =>
              RestaurantModel.fromMap(map.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      throw Exception('Unable to load saved restaurants.');
    }
  }

  Future<List<RestaurantModel>> getCommunityPlaces() async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        '''
        SELECT r.*, u.name AS created_by_name
        FROM ${AppConstants.restaurantsTable} r
        INNER JOIN ${AppConstants.usersTable} u
          ON u.id = r.created_by
        WHERE r.is_user_created = ?
        ORDER BY r.updated_at DESC, r.average_rating DESC
        ''',
        <Object>[AppConstants.boolTrue],
      );
      return result
          .map((Map<String, Object?> map) =>
              RestaurantModel.fromMap(map.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      throw Exception('Unable to load community picks.');
    }
  }

  Future<List<RestaurantModel>> getPlacesCreatedByUser(int userId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        '''
        SELECT r.*, u.name AS created_by_name
        FROM ${AppConstants.restaurantsTable} r
        LEFT JOIN ${AppConstants.usersTable} u
          ON u.id = r.created_by
        WHERE r.created_by = ?
        ORDER BY r.updated_at DESC
        ''',
        <Object>[userId],
      );
      return result
          .map((Map<String, Object?> map) =>
              RestaurantModel.fromMap(map.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      throw Exception('Unable to load your shared places.');
    }
  }

  Future<RestaurantModel?> getRestaurantById(int restaurantId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        '''
        SELECT r.*, u.name AS created_by_name
        FROM ${AppConstants.restaurantsTable} r
        LEFT JOIN ${AppConstants.usersTable} u
          ON u.id = r.created_by
        WHERE r.id = ?
        LIMIT 1
        ''',
        <Object>[restaurantId],
      );

      if (result.isEmpty) {
        return null;
      }

      return RestaurantModel.fromMap(result.first.cast<String, dynamic>());
    } catch (_) {
      throw Exception('Unable to load restaurant details.');
    }
  }

  Future<RestaurantModel> addUserPlace({
    required int userId,
    required RestaurantModel restaurant,
  }) async {
    try {
      _validateRestaurantInput(restaurant);
      final Database db = await _databaseService.database;
      final DateTime now = DateTime.now();
      final RestaurantModel record = restaurant.copyWith(
        remoteId: restaurant.remoteId.trim().isEmpty
            ? 'local_${userId}_${now.microsecondsSinceEpoch}'
            : restaurant.remoteId,
        isCached: true,
        isUserCreated: true,
        createdBy: userId,
        updatedAt: now,
      );

      final int id = await db.insert(
        AppConstants.restaurantsTable,
        record.toMap(),
      );

      return (await getRestaurantById(id)) ?? record.copyWith(id: id);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unable to add this place right now.');
    }
  }

  Future<RestaurantModel> updateUserPlace({
    required int userId,
    required RestaurantModel restaurant,
  }) async {
    try {
      if (restaurant.id == null) {
        throw Exception('Unable to update this place right now.');
      }

      _validateRestaurantInput(restaurant);
      final RestaurantModel? existing =
          await getRestaurantById(restaurant.id!);
      if (existing == null) {
        throw Exception('This place no longer exists.');
      }
      if (existing.createdBy != userId) {
        throw Exception(AppConstants.creatorOnlyMessage);
      }

      final Database db = await _databaseService.database;
      final RestaurantModel updated = restaurant.copyWith(
        remoteId: existing.remoteId,
        averageRating: existing.averageRating,
        reviewCount: existing.reviewCount,
        isCached: existing.isCached,
        isUserCreated: true,
        createdBy: userId,
        updatedAt: DateTime.now(),
      );

      await db.update(
        AppConstants.restaurantsTable,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[restaurant.id!],
      );

      return (await getRestaurantById(restaurant.id!)) ?? updated;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unable to update this place right now.');
    }
  }

  Future<void> deleteUserPlace({
    required int userId,
    required int restaurantId,
  }) async {
    try {
      final RestaurantModel? existing = await getRestaurantById(restaurantId);
      if (existing == null) {
        throw Exception('This place no longer exists.');
      }
      if (existing.createdBy != userId) {
        throw Exception(AppConstants.creatorOnlyMessage);
      }

      final Database db = await _databaseService.database;
      await db.delete(
        AppConstants.restaurantsTable,
        where: 'id = ?',
        whereArgs: <Object>[restaurantId],
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unable to delete this place right now.');
    }
  }

  bool _hasValidCache(List<RestaurantModel> restaurants) {
    if (restaurants.isEmpty) {
      return false;
    }

    final Iterable<RestaurantModel> remoteRestaurants = restaurants.where(
      (RestaurantModel restaurant) => !restaurant.isUserCreated,
    );
    if (remoteRestaurants.isEmpty) {
      return false;
    }

    final RestaurantModel latestRestaurant = remoteRestaurants.first;
    return DateTime.now()
            .difference(latestRestaurant.updatedAt)
            .inMinutes <
        AppConstants.cacheValidityInMinutes;
  }

  Future<void> _saveNearbyRestaurants(List<RestaurantModel> restaurants) async {
    try {
      final Database db = await _databaseService.database;

      await db.delete(
        AppConstants.restaurantsTable,
        where: 'is_user_created = ?',
        whereArgs: <Object>[AppConstants.boolFalse],
      );

      await db.transaction((Transaction transaction) async {
        for (final RestaurantModel restaurant in restaurants) {
          final List<Map<String, Object?>> existing = await transaction.query(
            AppConstants.restaurantsTable,
            where: 'remote_id = ?',
            whereArgs: <Object>[restaurant.remoteId],
            limit: 1,
          );

          if (existing.isEmpty) {
            await transaction.insert(
              AppConstants.restaurantsTable,
              restaurant.toMap(),
            );
          } else {
            final RestaurantModel saved = RestaurantModel.fromMap(
              existing.first.cast<String, dynamic>(),
            );
            final RestaurantModel updated = restaurant.copyWith(
              id: saved.id,
              averageRating: saved.averageRating,
              reviewCount: saved.reviewCount,
              description: saved.isUserCreated && saved.description.isNotEmpty
                  ? saved.description
                  : restaurant.description,
              imagePath: saved.imagePath,
              createdBy: saved.createdBy,
              isUserCreated: saved.isUserCreated,
            );
            await transaction.update(
              AppConstants.restaurantsTable,
              updated.toMap(),
              where: 'id = ?',
              whereArgs: <Object>[saved.id!],
            );
          }
        }
      });
    } catch (_) {
      throw Exception('Unable to cache nearby restaurants.');
    }
  }

  void _validateRestaurantInput(RestaurantModel restaurant) {
    if (restaurant.name.trim().isEmpty || restaurant.address.trim().isEmpty) {
      throw Exception(AppConstants.addPlaceValidationMessage);
    }

    if (!AppConstants.supportedPlaceTypes.contains(restaurant.placeType)) {
      throw Exception('Please choose a valid place type.');
    }
  }
}
