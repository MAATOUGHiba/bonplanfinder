import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/review_model.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/review_provider.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({
    required this.restaurantId,
    this.review,
    super.key,
  });

  final int restaurantId;
  final ReviewModel? review;

  bool get isEdit => review != null;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  double _rating = 4;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();

    if (widget.isEdit) {
      _rating = widget.review!.rating;
      _commentController.text = widget.review!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final AuthProvider authProvider = context.read<AuthProvider>();
      final ReviewProvider reviewProvider = context.read<ReviewProvider>();
      final RestaurantProvider restaurantProvider =
          context.read<RestaurantProvider>();

      final int? userId = authProvider.currentUser?.id;
      final String? userName = authProvider.currentUser?.name;
      if (userId == null || userName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in before posting a review.'),
          ),
        );
        return;
      }

      final DateTime now = DateTime.now();
      final ReviewModel review = ReviewModel(
        id: widget.review?.id,
        restaurantId: widget.restaurantId,
        userId: userId,
        userName: userName,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: widget.review?.createdAt ?? now,
        updatedAt: now,
      );

      final bool success = widget.isEdit
          ? await reviewProvider.updateReview(review)
          : await reviewProvider.addReview(review);

      if (!mounted) {
        return;
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewProvider.errorMessage ??
                  (widget.isEdit
                      ? 'Unable to update the review.'
                      : 'Unable to add the review.'),
            ),
          ),
        );
        return;
      }

      await restaurantProvider.refreshRestaurant(
        widget.restaurantId,
        userId: userId,
      );

      if (!mounted) {
        return;
      }

      final String successMessage = widget.isEdit
          ? 'Review updated successfully'
          : 'Review added successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ReviewProvider reviewProvider = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Review' : 'Add Review'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.isEdit
                            ? 'Update your review'
                            : 'Share your experience',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rate this place and leave a short comment for the community.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Rating: ${_rating.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        label: _rating.toStringAsFixed(1),
                        onChanged: (double value) {
                          setState(() {
                            _rating = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _commentController,
                        labelText: 'Comment',
                        hintText: 'What did you like or dislike?',
                        prefixIcon: Icons.rate_review_outlined,
                        validator: Validators.validateReviewComment,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: widget.isEdit ? 'Update Review' : 'Add Review',
                        icon: widget.isEdit
                            ? Icons.save_rounded
                            : Icons.send_rounded,
                        isLoading: reviewProvider.isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
