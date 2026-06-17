import 'package:geolocator/geolocator.dart';

import '../config/app_constants.dart';

class LocationService {
  const LocationService();

  Future<Position> getCurrentPosition() async {
    try {
      final bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw Exception(AppConstants.locationServiceDisabledMessage);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(AppConstants.locationPermissionDeniedMessage);
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(AppConstants.locationPermissionForeverDeniedMessage);
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      if (e is Exception &&
          (e.toString().contains('Location permission') ||
              e.toString().contains(AppConstants.locationServiceDisabledMessage))) {
        rethrow;
      }
      throw Exception('Unable to get your current location.');
    }
  }
}
