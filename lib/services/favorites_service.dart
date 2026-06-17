import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';
import '../models/favorite_model.dart';
import '../models/restaurant_model.dart';
import 'database_service.dart';

class FavoritesService {
  FavoritesService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<List<FavoriteModel>> getFavoritesByUser(int userId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> result = await db.query(
        AppConstants.favoritesTable,
        where: 'user_id = ?',
        whereArgs: <Object>[userId],
        orderBy: 'created_at DESC',
      );
      return result
          .map((Map<String, dynamic> map) => FavoriteModel.fromMap(map))
          .toList();
    } catch (_) {
      throw Exception('Unable to load favorites.');
    }
  }

  Future<List<RestaurantModel>> getFavoriteRestaurantsByUser(int userId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
        '''
        SELECT r.*
        FROM ${AppConstants.restaurantsTable} r
        INNER JOIN ${AppConstants.favoritesTable} f
          ON f.restaurant_id = r.id
        WHERE f.user_id = ?
        ORDER BY f.created_at DESC
        ''',
        <Object>[userId],
      );

      return result
          .map((Map<String, dynamic> map) => RestaurantModel.fromMap(map))
          .toList();
    } catch (_) {
      throw Exception('Unable to load favorite restaurants.');
    }
  }

  Future<bool> isFavorite({
    required int userId,
    required int restaurantId,
  }) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> result = await db.query(
        AppConstants.favoritesTable,
        where: 'user_id = ? AND restaurant_id = ?',
        whereArgs: <Object>[userId, restaurantId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (_) {
      throw Exception('Unable to check favorite status.');
    }
  }

  Future<void> addFavorite(FavoriteModel favorite) async {
    try {
      final Database db = await _databaseService.database;
      await db.insert(
        AppConstants.favoritesTable,
        favorite.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {
      throw Exception('Unable to save this restaurant to favorites.');
    }
  }

  Future<void> removeFavorite({
    required int userId,
    required int restaurantId,
  }) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete(
        AppConstants.favoritesTable,
        where: 'user_id = ? AND restaurant_id = ?',
        whereArgs: <Object>[userId, restaurantId],
      );
    } catch (_) {
      throw Exception('Unable to remove this favorite.');
    }
  }

  Future<Set<int>> getFavoriteRestaurantIds(int userId) async {
    try {
      final List<FavoriteModel> favorites = await getFavoritesByUser(userId);
      return favorites
          .map((FavoriteModel favorite) => favorite.restaurantId)
          .toSet();
    } catch (_) {
      throw Exception('Unable to load favorite status.');
    }
  }
}
