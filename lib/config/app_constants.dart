class AppConstants {
  const AppConstants._();

  
  static const String appName = 'BonPlanFinder';

  static const String databaseName = 'restaurant_finder.db';
  static const int databaseVersion = 4;

  static const String usersTable = 'users';
  static const String restaurantsTable = 'restaurants';
  static const String reviewsTable = 'reviews';
  static const String favoritesTable = 'favorites';

  static const String restaurantTypeRestaurant = 'Restaurant';
  static const String restaurantTypeCafe = 'Cafe';
  static const List<String> supportedPlaceTypes = <String>[
    restaurantTypeRestaurant,
    restaurantTypeCafe,
  ];

  static const String sessionUserIdKey = 'session_user_id';
  static const String sessionEmailKey = 'session_email';
  static const String sessionIsLoggedInKey = 'session_is_logged_in';

  static const String overpassApiUrl =
      'https://overpass-api.de/api/interpreter';
  static const List<String> overpassApiFallbackUrls = <String>[
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const int apiTimeoutSeconds = 20;
  static const int searchRadiusInMeters = 5000;
  static const int cacheValidityInMinutes = 30;
  static const int overpassResultLimit = 60;

  static const double defaultLatitude = 33.8869;
  static const double defaultLongitude = 9.5375;
  static const double defaultMapZoom = 14;
  static const double defaultRating = 0;
  static const int defaultReviewCount = 0;
  static const int minReviewRating = 1;
  static const int maxReviewRating = 5;
  static const int maxDescriptionLength = 500;
  static const int maxCommentLength = 400;
  static const int maxNameLength = 80;
  static const int maxAddressLength = 180;
  static const int maxCuisineLength = 80;
  static const int maxPhoneLength = 30;

  static const int boolFalse = 0;
  static const int boolTrue = 1;

  static const String locationPermissionDeniedMessage =
      'Location permission was denied. Please enable it to find nearby restaurants.';
  static const String locationPermissionForeverDeniedMessage =
      'Location permission is permanently denied. Please enable it in your device settings.';
  static const String locationServiceDisabledMessage =
      'Location services are disabled. Please enable GPS to discover nearby places.';
  static const String internetUnavailableMessage =
      'No internet connection is available right now.';
  static const String timeoutErrorMessage =
      'The request took too long. Please try again.';
  static const String cacheFallbackMessage =
      'Showing saved nearby places because live data could not be refreshed.';
  static const String addPlaceValidationMessage =
      'Please provide both a name and an address.';
  static const String deleteConfirmationMessage =
      'Are you sure you want to delete this place?';
  static const String creatorOnlyMessage =
      'Only the user who added this place can edit or delete it.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
}
