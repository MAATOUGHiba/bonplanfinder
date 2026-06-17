import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_constants.dart';
import 'config/app_theme.dart';
import 'models/review_model.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/review_provider.dart';
import 'screens/add_review_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/favorites_service.dart';
import 'services/location_service.dart';
import 'services/restaurant_service.dart';
import 'services/review_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DatabaseService databaseService = DatabaseService.instance;
  await databaseService.database;

  final AuthService authService = AuthService(
    databaseService: databaseService,
  );
  final LocationService locationService = const LocationService();
  final RestaurantService restaurantService = RestaurantService(
    databaseService: databaseService,
  );
  final ReviewService reviewService = ReviewService(
    databaseService: databaseService,
  );
  final FavoritesService favoritesService = FavoritesService(
    databaseService: databaseService,
  );

  runApp(
    RestaurantFinderApp(
      authService: authService,
      locationService: locationService,
      restaurantService: restaurantService,
      reviewService: reviewService,
      favoritesService: favoritesService,
    ),
  );
}

class RestaurantFinderApp extends StatelessWidget {
  RestaurantFinderApp({
    AuthService? authService,
    LocationService? locationService,
    RestaurantService? restaurantService,
    ReviewService? reviewService,
    FavoritesService? favoritesService,
    super.key,
  })  : authService = authService ?? AuthService(),
        locationService = locationService ?? const LocationService(),
        restaurantService = restaurantService ?? RestaurantService(),
        reviewService = reviewService ?? ReviewService(),
        favoritesService = favoritesService ?? FavoritesService();

  final AuthService authService;
  final LocationService locationService;
  final RestaurantService restaurantService;
  final ReviewService reviewService;
  final FavoritesService favoritesService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: authService,
          ),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(
            locationService: locationService,
          ),
        ),
        ChangeNotifierProvider<RestaurantProvider>(
          create: (_) => RestaurantProvider(
            restaurantService: restaurantService,
          ),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => ReviewProvider(
            reviewService: reviewService,
          ),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(
            favoritesService: favoritesService,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/add_review') {
            final Object? arguments = settings.arguments;
            if (arguments is ReviewModel) {
              return MaterialPageRoute<void>(
                builder: (_) => AddReviewScreen(
                  restaurantId: arguments.restaurantId,
                  review: arguments,
                ),
                settings: settings,
              );
            }

            if (arguments is Map) {
              final Object? restaurantIdValue = arguments['restaurantId'];
              final Object? reviewValue = arguments['review'];

              final int? restaurantId = restaurantIdValue is int
                  ? restaurantIdValue
                  : int.tryParse(restaurantIdValue?.toString() ?? '');
              final ReviewModel? review =
                  reviewValue is ReviewModel ? reviewValue : null;

              if (restaurantId != null) {
                return MaterialPageRoute<void>(
                  builder: (_) => AddReviewScreen(
                    restaurantId: restaurantId,
                    review: review,
                  ),
                  settings: settings,
                );
              }
            }
          }

          return null;
        },
        home: const SplashScreen(),
      ),
    );
  }
}
