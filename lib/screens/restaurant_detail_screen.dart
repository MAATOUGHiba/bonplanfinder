import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_constants.dart';
import '../models/restaurant_model.dart';
import '../models/review_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_stars.dart';
import 'add_review_screen.dart';
import 'add_place_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
  });

  final RestaurantModel restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isFavorite = false;

  List<MapEntry<String, String>> _extractApiDetails(String description) {
    return description
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.contains(':'))
        .map((String line) {
          final int separatorIndex = line.indexOf(':');
          final String label = line.substring(0, separatorIndex).trim();
          final String value = line.substring(separatorIndex + 1).trim();
          return MapEntry<String, String>(label, value);
        })
        .where(
          (MapEntry<String, String> entry) =>
              entry.key.isNotEmpty && entry.value.isNotEmpty,
        )
        .toList();
  }

  String _extractNarrativeDescription(String description) {
    return description
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty && !line.contains(':'))
        .join('\n');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPageData();
    });
  }

  Future<void> _loadPageData() async {
    try {
      final int? userId = context.read<AuthProvider>().currentUser?.id;
      final int? restaurantId = widget.restaurant.id;
      if (restaurantId == null) {
        return;
      }

      await context.read<ReviewProvider>().loadReviews(
            restaurantId,
            currentUserId: userId,
          );
      if (!mounted) {
        return;
      }

      await context.read<RestaurantProvider>().refreshRestaurant(
            restaurantId,
            userId: userId,
          );
      if (!mounted) {
        return;
      }

      await _refreshFavoriteState();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load place details.')),
      );
    }
  }

  Future<void> _refreshFavoriteState() async {
    try {
      final int? userId = context.read<AuthProvider>().currentUser?.id;
      final int? restaurantId = widget.restaurant.id;
      if (userId == null || restaurantId == null) {
        return;
      }

      final bool favorite = await context.read<FavoritesProvider>().isFavorite(
            userId: userId,
            restaurantId: restaurantId,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = favorite;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to refresh favorite state.')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final int? userId = context.read<AuthProvider>().currentUser?.id;
      final int? restaurantId = _currentRestaurant.id;
      if (userId == null || restaurantId == null) {
        return;
      }

      await context.read<FavoritesProvider>().toggleFavorite(
            userId: userId,
            restaurantId: restaurantId,
          );
      await _refreshFavoriteState();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite status.')),
      );
    }
  }

  RestaurantModel get _currentRestaurant {
    final RestaurantProvider restaurantProvider =
        context.read<RestaurantProvider>();
    final List<RestaurantModel> matches = restaurantProvider.allRestaurants
        .where((RestaurantModel item) => item.id == widget.restaurant.id)
        .toList();
    return matches.isNotEmpty ? matches.first : widget.restaurant;
  }

  Future<void> _openAddReviewScreen({ReviewModel? review}) async {
    try {
      final int? restaurantId = _currentRestaurant.id;
      if (restaurantId == null) {
        return;
      }

      final bool? result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => AddReviewScreen(
            restaurantId: restaurantId,
            review: review,
          ),
        ),
      );

      if (result == true && mounted) {
        await _loadPageData();
        if (!mounted) {
          return;
        }
        setState(() {});
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the review screen.')),
      );
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete review'),
          content: const Text('Are you sure you want to delete this review?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final int? currentUserId = context.read<AuthProvider>().currentUser?.id;
      final ReviewProvider reviewProvider = context.read<ReviewProvider>();
      final RestaurantProvider restaurantProvider =
          context.read<RestaurantProvider>();

      final bool success = await reviewProvider.deleteReview(
        reviewId: review.id ?? 0,
        restaurantId: review.restaurantId,
        currentUserId: currentUserId,
      );

      if (!success) {
        throw Exception(
          reviewProvider.errorMessage ?? 'Unable to delete the review.',
        );
      }

      await restaurantProvider.refreshRestaurant(
        review.restaurantId,
        userId: currentUserId,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully.')),
      );
      setState(() {});
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

  Future<void> _editPlace(RestaurantModel restaurant) async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddPlaceScreen(restaurant: restaurant),
      ),
    );

    if (updated == true && mounted) {
      await _loadPageData();
    }
  }

  Future<void> _deletePlace(RestaurantModel restaurant) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete place'),
          content: const Text(AppConstants.deleteConfirmationMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted || restaurant.id == null) {
      return;
    }

    try {
      final int? userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) {
        return;
      }

      final bool success = await context.read<RestaurantProvider>().deletePlace(
            userId: userId,
            restaurantId: restaurant.id!,
          );
      if (!mounted) {
        return;
      }

      if (!success) {
        throw Exception(
          context.read<RestaurantProvider>().errorMessage ??
              'Unable to delete this place.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place deleted successfully.')),
      );
      Navigator.of(context).pop(true);
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
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final ReviewProvider reviewProvider = context.watch<ReviewProvider>();
    final RestaurantModel restaurant = _currentRestaurant;
    final bool isCreator = restaurant.createdBy == authProvider.currentUser?.id;
    final List<MapEntry<String, String>> apiDetails =
        _extractApiDetails(restaurant.description);
    final String narrativeDescription =
        _extractNarrativeDescription(restaurant.description);
    final List<String> placeImages = restaurant.imagePaths;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place details'),
        actions: <Widget>[
          if (restaurant.id != null)
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? const Color(0xFFDC2626) : null,
              ),
            ),
          if (isCreator) ...<Widget>[
            IconButton(
              onPressed: () => _editPlace(restaurant),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () => _deletePlace(restaurant),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddReviewScreen(review: reviewProvider.myReview),
        icon: const Icon(Icons.rate_review_rounded),
        label: Text(reviewProvider.myReview == null ? 'Add Review' : 'Edit Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (placeImages.isNotEmpty) ...<Widget>[
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: placeImages.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final String imagePath = placeImages[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: placeImages.length == 1 ? 320 : 280,
                              color: const Color(0xFFF1EEE3),
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Text(
                        restaurant.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (restaurant.isUserCreated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE7D8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('User Added'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    restaurant.hasCuisine
                        ? '${restaurant.placeType} - ${restaurant.cuisine}'
                        : restaurant.placeType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF14532D),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      RatingStars(rating: restaurant.averageRating, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${restaurant.averageRating.toStringAsFixed(1)} average | ${restaurant.reviewCount} reviews',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Address'),
                    subtitle: Text(restaurant.address),
                  ),
                  if (restaurant.hasCuisine)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restaurant_menu_rounded),
                      title: const Text('Cuisine'),
                      subtitle: Text(restaurant.cuisine),
                    ),
                  if (restaurant.hasPhone)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      subtitle: Text(restaurant.phone),
                    ),
                  if (narrativeDescription.trim().isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notes_rounded),
                      title: const Text('Description'),
                      subtitle: Text(narrativeDescription),
                    ),
                  if (apiDetails.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      'Place details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...apiDetails.map(
                      (MapEntry<String, String> detail) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(detail.key),
                        subtitle: Text(detail.value),
                      ),
                    ),
                  ],
                  if (restaurant.createdByName != null &&
                      restaurant.createdByName!.trim().isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Added by'),
                      subtitle: Text(restaurant.createdByName!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reviews',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          if (reviewProvider.isLoading && reviewProvider.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (reviewProvider.reviews.isEmpty)
            const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No reviews yet',
              message: 'Be the first to share your experience for this place.',
            )
          else
            ...reviewProvider.reviews.map((ReviewModel review) {
              final bool canEdit = review.userId == authProvider.currentUser?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ReviewCard(
                  review: review,
                  canEdit: canEdit,
                  onEdit: () => _openAddReviewScreen(review: review),
                  onDelete: () => _deleteReview(review),
                ),
              );
            }),
        ],
      ),
    );
  }
}
