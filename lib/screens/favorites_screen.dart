import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int? userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<FavoritesProvider>().loadFavorites(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int? userId = context.watch<AuthProvider>().currentUser?.id;

    return Consumer<FavoritesProvider>(
      builder: (
        BuildContext context,
        FavoritesProvider favoritesProvider,
        Widget? child,
      ) {
        if (favoritesProvider.isLoading &&
            favoritesProvider.favoriteRestaurants.isEmpty) {
          return const LoadingView(message: 'Loading favorites...');
        }

        if (favoritesProvider.errorMessage != null &&
            favoritesProvider.favoriteRestaurants.isEmpty) {
          return ErrorView(
            message: favoritesProvider.errorMessage!,
            onRetry: userId == null
                ? null
                : () => favoritesProvider.loadFavorites(userId),
          );
        }

        if (favoritesProvider.favoriteRestaurants.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No favorites yet',
            message:
                'Save restaurants and cafes you love, and they will appear here for quick access.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: favoritesProvider.favoriteRestaurants.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 14),
          itemBuilder: (BuildContext context, int index) {
            final RestaurantModel restaurant =
                favoritesProvider.favoriteRestaurants[index];
            return RestaurantCard(
              restaurant: restaurant,
              isFavorite: restaurant.id != null,
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
                    builder: (BuildContext context) =>
                        RestaurantDetailScreen(restaurant: restaurant),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
