import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_screen.dart';

class NearbyPlacesScreen extends StatelessWidget {
  const NearbyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RestaurantProvider restaurantProvider =
        context.watch<RestaurantProvider>();
    final FavoritesProvider favoritesProvider =
        context.watch<FavoritesProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final int? userId = authProvider.currentUser?.id;
    final List<RestaurantModel> nearbyRestaurants = restaurantProvider.restaurants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Places'),
      ),
      body: nearbyRestaurants.isEmpty
          ? const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No nearby places found',
              message:
                  'Try refreshing your location or changing the search keyword.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: nearbyRestaurants.length,
              itemBuilder: (BuildContext context, int index) {
                final RestaurantModel restaurant = nearbyRestaurants[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RestaurantCard(
                    restaurant: restaurant,
                    isFavorite: restaurant.id != null &&
                        favoritesProvider.isFavoriteLocal(restaurant.id!),
                    onFavoriteTap: userId == null || restaurant.id == null
                        ? null
                        : () {
                            favoritesProvider.toggleFavorite(
                              userId: userId,
                              restaurantId: restaurant.id!,
                            );
                          },
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RestaurantDetailScreen(
                            restaurant: restaurant,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
