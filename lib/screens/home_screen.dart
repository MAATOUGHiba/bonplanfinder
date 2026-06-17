import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/restaurant_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/location_provider.dart';
import '../providers/restaurant_provider.dart';
import '../screens/add_place_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/nearby_places_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _didLoadInitialData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialData) {
      return;
    }
    _didLoadInitialData = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppData({bool forceRefresh = false}) async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final LocationProvider locationProvider = context.read<LocationProvider>();
    final RestaurantProvider restaurantProvider =
        context.read<RestaurantProvider>();
    final FavoritesProvider favoritesProvider =
        context.read<FavoritesProvider>();

    final int? userId = authProvider.currentUser?.id;
    if (userId != null) {
      await favoritesProvider.loadFavorites(userId);
    }

    final bool locationSuccess = await locationProvider.fetchCurrentLocation();
    final Position? position = locationProvider.currentPosition;

    if (locationSuccess && position != null) {
      await restaurantProvider.loadNearbyRestaurants(
        latitude: position.latitude,
        longitude: position.longitude,
        userId: userId,
        forceRefresh: forceRefresh,
      );
      return;
    }

    await restaurantProvider.loadCommunityData(userId: userId);
  }

  Future<void> _openAddPlace() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddPlaceScreen(),
      ),
    );

    if (created == true && mounted) {
      await _loadAppData(forceRefresh: false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community place shared successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _DiscoverTab(
        searchController: _searchController,
        onRefresh: () => _loadAppData(forceRefresh: true),
        onAddPlace: _openAddPlace,
      ),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'BonPlanFinder'
              : _currentIndex == 1
                  ? 'Favorites'
                  : 'Profile',
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddPlace,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('+ Add Place'),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({
    required this.searchController,
    required this.onRefresh,
    required this.onAddPlace,
  });

  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onAddPlace;

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final FavoritesProvider favoritesProvider =
        context.watch<FavoritesProvider>();
    final LocationProvider locationProvider = context.watch<LocationProvider>();
    final RestaurantProvider restaurantProvider =
        context.watch<RestaurantProvider>();
    final int? userId = authProvider.currentUser?.id;
    final List<RestaurantModel> visibleNearbyRestaurants =
        restaurantProvider.nearbyPreviewRestaurants;
    final List<RestaurantModel> allNearbyRestaurants = restaurantProvider.restaurants;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF14532D),
                  Color(0xFF0EA5A4),
                  Color(0xFFF59E0B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Find nearby spots and community picks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover places around you, keep favorites in sync, and share your own restaurant and cafe recommendations.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () {
                        onAddPlace();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF14532D),
                      ),
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('+ Add Place'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        onRefresh();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            onChanged: restaurantProvider.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search by name, type, cuisine, or address',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          if (restaurantProvider.errorMessage != null &&
              restaurantProvider.allRestaurants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _StatusBanner(
                message: restaurantProvider.errorMessage!,
                icon: Icons.error_outline_rounded,
                backgroundColor: const Color(0xFFFEE4E2),
                foregroundColor: const Color(0xFFB42318),
              ),
            ),
          if (restaurantProvider.infoMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _StatusBanner(
                message: restaurantProvider.infoMessage!,
                icon: Icons.info_outline_rounded,
                backgroundColor: const Color(0xFFE0F2FE),
                foregroundColor: const Color(0xFF075985),
              ),
            ),
          if (locationProvider.errorMessage != null &&
              restaurantProvider.allRestaurants.isEmpty)
            ErrorView(
              message: locationProvider.errorMessage!,
              onRetry: () {
                onRefresh();
              },
            )
          else if (restaurantProvider.errorMessage != null &&
              restaurantProvider.allRestaurants.isEmpty)
            ErrorView(
              message: restaurantProvider.errorMessage!,
              onRetry: () {
                onRefresh();
              },
            )
          else ...<Widget>[
            _SectionHeader(
              title: 'Nearby Discovery',
              subtitle: restaurantProvider.hasActiveSearch
                  ? 'Found ${allNearbyRestaurants.length} nearby matches from your current search.'
                  : 'Showing the closest ${visibleNearbyRestaurants.length} of ${allNearbyRestaurants.length} nearby restaurants and cafes.',
            ),
            const SizedBox(height: 12),
            if (restaurantProvider.isLoading &&
                restaurantProvider.allRestaurants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (allNearbyRestaurants.isEmpty)
              EmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: restaurantProvider.errorMessage != null
                    ? 'Unable to load nearby places'
                    : 'No places found',
                message: restaurantProvider.errorMessage ??
                    'Try refreshing your location or searching with a different keyword.',
              )
            else
              ...visibleNearbyRestaurants.map(
                (RestaurantModel restaurant) => Padding(
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
                ),
              ),
            if (restaurantProvider.hasMoreNearbyResults) ...<Widget>[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NearbyPlacesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.read_more_rounded),
                  label: Text(
                    'Show more (${allNearbyRestaurants.length - visibleNearbyRestaurants.length} more)',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _SectionHeader(
              title: 'Community Picks',
              subtitle: 'Shared by BonPlanFinder users around the area.',
            ),
            const SizedBox(height: 12),
            if (restaurantProvider.communityPicks.isEmpty)
              const EmptyState(
                icon: Icons.groups_rounded,
                title: 'No community picks yet',
                message:
                    'Tap "+ Add Place" to share the first local recommendation.',
              )
            else
              ...restaurantProvider.communityPicks.map(
                (RestaurantModel restaurant) => Padding(
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
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
