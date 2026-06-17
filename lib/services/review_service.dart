import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';
import '../models/review_model.dart';
import 'database_service.dart';

class ReviewService {
  ReviewService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<List<ReviewModel>> getReviewsByRestaurant(int restaurantId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> result = await db.query(
        AppConstants.reviewsTable,
        where: 'restaurant_id = ?',
        whereArgs: <Object>[restaurantId],
        orderBy: 'updated_at DESC',
      );
      return result
          .map((Map<String, dynamic> map) => ReviewModel.fromMap(map))
          .toList();
    } catch (_) {
      throw Exception('Unable to load reviews.');
    }
  }

  Future<void> addReview(ReviewModel review) async {
    try {
      _validateReview(review);
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> existing = await db.query(
        AppConstants.reviewsTable,
        where: 'restaurant_id = ? AND user_id = ?',
        whereArgs: <Object>[review.restaurantId, review.userId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw Exception('You have already reviewed this place.');
      }

      await db.insert(AppConstants.reviewsTable, review.toMap());
      await _updateRestaurantRating(review.restaurantId);
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('already reviewed this place')) {
        rethrow;
      }
      throw Exception('Unable to add your review.');
    }
  }

  Future<int> updateReview(ReviewModel review) async {
    try {
      if (review.id == null) {
        throw Exception('Unable to update your review.');
      }
      _validateReview(review);
      final Database db = await _databaseService.database;
      final int result = await db.update(
        AppConstants.reviewsTable,
        review.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[review.id!],
      );
      if (result == 0) {
        throw Exception('Review not found.');
      }
      await _updateRestaurantRating(review.restaurantId);
      return result;
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('Review not found.')) {
        rethrow;
      }
      throw Exception('Unable to update your review.');
    }
  }

  Future<void> deleteReview({
    required int reviewId,
    required int restaurantId,
  }) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete(
        AppConstants.reviewsTable,
        where: 'id = ?',
        whereArgs: <Object>[reviewId],
      );
      await _updateRestaurantRating(restaurantId);
    } catch (_) {
      throw Exception('Unable to delete the review.');
    }
  }

  Future<ReviewModel?> getReviewByUser({
    required int restaurantId,
    required int userId,
  }) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> result = await db.query(
        AppConstants.reviewsTable,
        where: 'restaurant_id = ? AND user_id = ?',
        whereArgs: <Object>[restaurantId, userId],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      return ReviewModel.fromMap(result.first.cast<String, dynamic>());
    } catch (_) {
      throw Exception('Unable to load your review.');
    }
  }

  Future<void> _updateRestaurantRating(int restaurantId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        '''
        SELECT
          AVG(rating) AS average_rating,
          COUNT(*) AS review_count
        FROM ${AppConstants.reviewsTable}
        WHERE restaurant_id = ?
        ''',
        <Object>[restaurantId],
      );

      final double averageRating =
          (result.first['average_rating'] as num?)?.toDouble() ?? 0;
      final int reviewCount = (result.first['review_count'] as int?) ?? 0;

      await db.update(
        AppConstants.restaurantsTable,
        <String, Object>{
          'average_rating': averageRating,
          'review_count': reviewCount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: <Object>[restaurantId],
      );
    } catch (_) {
      throw Exception('Unable to update the restaurant rating.');
    }
  }

  void _validateReview(ReviewModel review) {
    if (review.comment.trim().isEmpty) {
      throw Exception('Please write a short review.');
    }
    if (review.rating < AppConstants.minReviewRating ||
        review.rating > AppConstants.maxReviewRating) {
      throw Exception('Please provide a rating between 1 and 5.');
    }
  }
}
