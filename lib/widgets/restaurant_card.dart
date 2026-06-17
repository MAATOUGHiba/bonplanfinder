import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';
import 'rating_stars.dart';

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.trailing,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final RestaurantModel restaurant;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: restaurant.isCafe
                        ? const <Color>[
                            Color(0xFFB45309),
                            Color(0xFFF59E0B),
                          ]
                        : const <Color>[
                            Color(0xFF14532D),
                            Color(0xFF0EA5A4),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  restaurant.isCafe
                      ? Icons.local_cafe_rounded
                      : Icons.restaurant_menu_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          restaurant.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
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
                            child: Text(
                              'User Added',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF9A3412),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.hasCuisine
                          ? '${restaurant.placeType} • ${restaurant.cuisine}'
                          : restaurant.placeType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF14532D),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (restaurant.createdByName != null &&
                        restaurant.createdByName!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Added by ${restaurant.createdByName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF0F766E),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    if (restaurant.hasDescription) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        restaurant.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        RatingStars(rating: restaurant.averageRating),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${restaurant.averageRating.toStringAsFixed(1)} (${restaurant.reviewCount})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  if (onFavoriteTap != null)
                    IconButton(
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xFFDC2626) : null,
                      ),
                    ),
                  if (trailing case final Widget trailingWidget) trailingWidget,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
