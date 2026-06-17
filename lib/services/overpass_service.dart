import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_constants.dart';
import '../models/restaurant_model.dart';

class OverpassService {
  const OverpassService();

  Future<List<RestaurantModel>> fetchNearbyRestaurants({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final List<InternetAddress> lookupResult =
          await InternetAddress.lookup('overpass-api.de');
      if (lookupResult.isEmpty) {
        throw Exception(AppConstants.internetUnavailableMessage);
      }

      final String query = '''
[out:json][timeout:${AppConstants.apiTimeoutSeconds}];
(
  node["amenity"="restaurant"](around:${AppConstants.searchRadiusInMeters},$latitude,$longitude);
  way["amenity"="restaurant"](around:${AppConstants.searchRadiusInMeters},$latitude,$longitude);
  relation["amenity"="restaurant"](around:${AppConstants.searchRadiusInMeters},$latitude,$longitude);
);
out center tags;
''';

      final http.Response response = await http
          .post(
            Uri.parse(AppConstants.overpassApiUrl),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: <String, String>{'data': query},
          )
          .timeout(
            const Duration(seconds: AppConstants.apiTimeoutSeconds),
          );

      if (response.statusCode != 200) {
        throw Exception('Unable to fetch restaurant data right now.');
      }

      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> elements = decoded['elements'] as List<dynamic>? ?? <dynamic>[];

      return elements
          .map((dynamic item) => _mapRestaurant(item as Map<String, dynamic>))
          .where((RestaurantModel restaurant) => restaurant.name.isNotEmpty)
          .toList();
    } on SocketException {
      throw Exception(AppConstants.internetUnavailableMessage);
    } on TimeoutException {
      throw Exception('The restaurant search timed out. Please try again.');
    } catch (e) {
      if (e is Exception &&
          (e.toString().contains(AppConstants.internetUnavailableMessage) ||
              e.toString().contains('timed out') ||
              e.toString().contains('Unable to fetch restaurant data'))) {
        rethrow;
      }
      throw Exception('Unable to fetch nearby restaurants.');
    }
  }

  RestaurantModel _mapRestaurant(Map<String, dynamic> item) {
    final Map<String, dynamic> tags =
        item['tags'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final double latitude =
        (item['lat'] as num?)?.toDouble() ??
            (item['center']?['lat'] as num?)?.toDouble() ??
            0;
    final double longitude =
        (item['lon'] as num?)?.toDouble() ??
            (item['center']?['lon'] as num?)?.toDouble() ??
            0;

    final String street = tags['addr:street'] as String? ?? '';
    final String houseNumber = tags['addr:housenumber'] as String? ?? '';
    final String city = tags['addr:city'] as String? ?? '';
    final String address = <String>[houseNumber, street, city]
        .where((String part) => part.trim().isNotEmpty)
        .join(', ');
    final String amenity = (tags['amenity'] as String? ?? '').toLowerCase();

    return RestaurantModel(
      remoteId: '${item['type']}_${item['id']}',
      name: tags['name'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      address: address.isEmpty ? 'Address unavailable' : address,
      placeType: amenity == 'cafe'
          ? AppConstants.restaurantTypeCafe
          : AppConstants.restaurantTypeRestaurant,
      cuisine: tags['cuisine'] as String? ?? '',
      phone: tags['phone'] as String? ?? '',
      description: tags['description'] as String? ?? '',
      imagePath: '',
      averageRating: 0,
      reviewCount: 0,
      isCached: true,
      isUserCreated: false,
      createdBy: null,
      updatedAt: DateTime.now(),
    );
  }
}
