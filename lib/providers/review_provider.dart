import 'package:flutter/foundation.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewService? reviewService})
      : _reviewService = reviewService ?? ReviewService();

  final ReviewService _reviewService;

  List<ReviewModel> _reviews = <ReviewModel>[];
  ReviewModel? _myReview;
  bool _isLoading = false;
  String? _errorMessage;

  List<ReviewModel> get reviews => _reviews;
  ReviewModel? get myReview => _myReview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReviews(int restaurantId, {int? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getReviewsByRestaurant(restaurantId);
      _myReview = currentUserId == null
          ? null
          : await _reviewService.getReviewByUser(
              restaurantId: restaurantId,
              userId: currentUserId,
            );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.addReview(review);
      await loadReviews(
        review.restaurantId,
        currentUserId: review.userId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview(ReviewModel review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final int updatedRows = await _reviewService.updateReview(review);
      if (updatedRows == 0) {
        throw Exception('Review not found.');
      }

      await loadReviews(
        review.restaurantId,
        currentUserId: review.userId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview({
    required int reviewId,
    required int restaurantId,
    int? currentUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.deleteReview(
        reviewId: reviewId,
        restaurantId: restaurantId,
      );
      await loadReviews(
        restaurantId,
        currentUserId: currentUserId,
      );
      return true;
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
