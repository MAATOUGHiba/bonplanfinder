import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../models/restaurant_model.dart';

class ApiService {
  const ApiService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<RestaurantModel>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint(
        'ApiService.fetchNearbyPlaces -> lat=$latitude, lng=$longitude',
      );

      final List<InternetAddress> lookupResult =
          await InternetAddress.lookup('overpass-api.de');
      if (lookupResult.isEmpty) {
        throw Exception(AppConstants.internetUnavailableMessage);
      }

      final http.Client client = _client ?? http.Client();
      try {
        final String query = _buildOverpassQuery(
          latitude: latitude,
          longitude: longitude,
        );

        final List<String> endpoints = <String>[
          AppConstants.overpassApiUrl,
          ...AppConstants.overpassApiFallbackUrls,
        ];

        Exception? lastException;
        for (final String endpoint in endpoints) {
          try {
            final List<RestaurantModel> results = await _fetchFromEndpoint(
              client: client,
              endpoint: endpoint,
              query: query,
            );

            if (results.isNotEmpty) {
              return results;
            }
          } catch (e) {
            debugPrint('ApiService -> endpoint failed: $endpoint -> $e');
            if (e is Exception) {
              lastException = e;
            } else {
              lastException = Exception('Unable to fetch nearby places.');
            }
          }
        }

        if (lastException != null) {
          throw lastException;
        }

        throw Exception('No nearby restaurants or cafes were found.');
      } finally {
        if (_client == null) {
          client.close();
        }
      }
    } on SocketException {
      debugPrint('ApiService -> No internet connection.');
      throw Exception(AppConstants.internetUnavailableMessage);
    } on TimeoutException {
      debugPrint('ApiService -> Request timed out.');
      throw Exception(AppConstants.timeoutErrorMessage);
    } on FormatException {
      debugPrint('ApiService -> Invalid API response.');
      throw Exception('Received an invalid response from the places service.');
    } catch (e) {
      debugPrint('ApiService -> Error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unable to fetch nearby places.');
    }
  }

  Future<List<RestaurantModel>> _fetchFromEndpoint({
    required http.Client client,
    required String endpoint,
    required String query,
  }) async {
    final Uri uri = Uri.parse(endpoint).replace(
      queryParameters: <String, String>{
        'data': query,
      },
    );

    final http.Response response = await client
        .get(
          uri,
          headers: <String, String>{
            'User-Agent': 'BonPlanFinder/1.0 (Flutter)',
            'Accept': '*/*',
          },
        )
        .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

    debugPrint('ApiService -> uri=$uri');
    debugPrint(
      'ApiService -> status=${response.statusCode}, body=${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to load nearby places right now. Server responded with ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String? remark = decoded['remark'] as String?;
    if (remark != null && remark.trim().isNotEmpty) {
      throw Exception('Places service error: $remark');
    }
    final List<dynamic> elements =
        decoded['elements'] as List<dynamic>? ?? <dynamic>[];

    final List<RestaurantModel> results = elements
        .map((dynamic item) => _mapRestaurant(item as Map<String, dynamic>))
        .where((RestaurantModel restaurant) {
          return restaurant.latitude != 0 && restaurant.longitude != 0;
        })
        .take(AppConstants.overpassResultLimit)
        .toList();

    debugPrint('ApiService -> results=${results.length}');
    if (results.isEmpty) {
      throw Exception(
        'No nearby restaurants or cafes were found for your current location.',
      );
    }
    return _deduplicateResults(results);
  }

  String _buildOverpassQuery({
    required double latitude,
    required double longitude,
  }) {
    return '''
[out:json][timeout:${AppConstants.apiTimeoutSeconds}];
(
  node["amenity"~"restaurant|cafe"](around:${AppConstants.searchRadiusInMeters},$latitude,$longitude);
  way["amenity"~"restaurant|cafe"](around:${AppConstants.searchRadiusInMeters},$latitude,$longitude);
  relation["amenity"~"restaurant|cafe"](around:${AppConstants.searchRadiusInMeters},$latitude,$longitude);
);
out center tags;
''';
  }

  List<RestaurantModel> _deduplicateResults(List<RestaurantModel> results) {
    final Map<String, RestaurantModel> deduplicated =
        <String, RestaurantModel>{};
    for (final RestaurantModel result in results) {
      deduplicated[result.remoteId] = result;
    }
    return deduplicated.values.toList();
  }

  RestaurantModel _mapRestaurant(Map<String, dynamic> item) {
    final Map<String, dynamic> tags =
        item['tags'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> center =
        item['center'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final double latitude = (item['lat'] as num?)?.toDouble() ??
        (center['lat'] as num?)?.toDouble() ??
        0;
    final double longitude = (item['lon'] as num?)?.toDouble() ??
        (center['lon'] as num?)?.toDouble() ??
        0;

    final String amenity = (tags['amenity'] as String? ?? '').toLowerCase();
    final String placeType = amenity == 'cafe'
        ? AppConstants.restaurantTypeCafe
        : AppConstants.restaurantTypeRestaurant;

    final String address = _resolveAddress(tags);
    final String fallbackName = placeType == AppConstants.restaurantTypeCafe
        ? 'Unnamed Cafe'
        : 'Unnamed Restaurant';

    return RestaurantModel(
      remoteId: '${item['type']}_${item['id']}',
      name: tags['name'] as String? ?? fallbackName,
      latitude: latitude,
      longitude: longitude,
      address: address,
      placeType: placeType,
      cuisine: _resolveCuisine(tags, placeType),
      phone: _resolvePhone(tags),
      description: _resolveDescription(tags),
      imagePath: '',
      averageRating: AppConstants.defaultRating,
      reviewCount: AppConstants.defaultReviewCount,
      isCached: true,
      isUserCreated: false,
      createdBy: null,
      updatedAt: DateTime.now(),
    );
  }

  String _resolveAddress(Map<String, dynamic> tags) {
    final List<String> parts = <String>[
      _cleanTag(tags['addr:housenumber']),
      _cleanTag(tags['addr:street']),
      _cleanTag(tags['addr:suburb']),
      _cleanTag(tags['addr:neighbourhood']),
      _cleanTag(tags['addr:city']),
      _cleanTag(tags['addr:postcode']),
    ].where((String part) => part.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      final List<String> fallbacks = <String>[
        _cleanTag(tags['addr:full']),
        _cleanTag(tags['contact:street']),
        _cleanTag(tags['street']),
        _cleanTag(tags['addr:place']),
      ];
      for (final String fallback in fallbacks) {
        if (fallback.trim().isNotEmpty) {
          return fallback;
        }
      }
      return 'Address unavailable';
    }

    return parts.join(', ');
  }

  String _resolvePhone(Map<String, dynamic> tags) {
    final List<String> phoneCandidates = <String>[
      _cleanTag(tags['phone']),
      _cleanTag(tags['contact:phone']),
      _cleanTag(tags['mobile']),
      _cleanTag(tags['contact:mobile']),
    ];

    for (final String candidate in phoneCandidates) {
      if (candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return '';
  }

  String _resolveCuisine(Map<String, dynamic> tags, String placeType) {
    final String rawCuisine = _cleanTag(tags['cuisine']);
    if (rawCuisine.isEmpty) {
      return '';
    }

    final List<String> formattedParts = rawCuisine
        .split(';')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .map(_titleCaseCuisine)
        .toList();

    final String formattedCuisine = formattedParts.join(', ');
    if (formattedCuisine.toLowerCase() == placeType.toLowerCase()) {
      return '';
    }
    return formattedCuisine;
  }

  String _resolveDescription(Map<String, dynamic> tags) {
    final String explicitDescription = _cleanTag(tags['description']);
    if (explicitDescription.isNotEmpty) {
      return explicitDescription;
    }

    final List<String> details = <String>[];
    _addDetail(details, 'Opening hours', tags['opening_hours']);
    _addDetail(details, 'Internet', _friendlyYesNo(tags['internet_access']));
    _addDetail(details, 'Air conditioning', _friendlyYesNo(tags['air_conditioning']));
    _addDetail(details, 'Indoor seating', _friendlyYesNo(tags['indoor_seating']));
    _addDetail(details, 'Outdoor seating', _friendlyYesNo(tags['outdoor_seating']));
    _addDetail(details, 'Smoking', _friendlySmoking(tags['smoking']));
    _addDetail(details, 'Wheelchair access', _friendlyYesNo(tags['wheelchair']));
    _addDetail(details, 'Halal', _friendlyDiet(tags['diet:halal']));

    return details.join('\n');
  }

  void _addDetail(List<String> details, String label, Object? value) {
    final String cleaned = _cleanTag(value);
    if (cleaned.isEmpty) {
      return;
    }
    details.add('$label: $cleaned');
  }

  String _friendlyYesNo(Object? value) {
    final String cleaned = _cleanTag(value).toLowerCase();
    switch (cleaned) {
      case 'yes':
      case 'true':
        return 'Yes';
      case 'no':
      case 'false':
        return 'No';
      default:
        return _cleanTag(value);
    }
  }

  String _friendlySmoking(Object? value) {
    final String cleaned = _cleanTag(value).toLowerCase();
    switch (cleaned) {
      case 'no':
        return 'Not allowed';
      case 'yes':
        return 'Allowed';
      default:
        return _cleanTag(value);
    }
  }

  String _friendlyDiet(Object? value) {
    final String cleaned = _cleanTag(value).toLowerCase();
    switch (cleaned) {
      case 'only':
        return 'Halal only';
      case 'yes':
        return 'Available';
      case 'no':
        return 'Not specified';
      default:
        return _cleanTag(value);
    }
  }

  String _titleCaseCuisine(String value) {
    if (value.isEmpty) {
      return '';
    }

    return value
        .split(RegExp(r'[_\s-]+'))
        .where((String part) => part.isNotEmpty)
        .map((String part) {
      final String lower = part.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  String _cleanTag(Object? value) {
    return value?.toString().trim() ?? '';
  }
}
