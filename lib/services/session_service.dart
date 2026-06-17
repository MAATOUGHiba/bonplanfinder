import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';

class SessionService {
  const SessionService();

  Future<void> saveSession({
    required int userId,
    required String email,
  }) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setBool(AppConstants.sessionIsLoggedInKey, true);
      await preferences.setInt(AppConstants.sessionUserIdKey, userId);
      await preferences.setString(AppConstants.sessionEmailKey, email);
    } catch (_) {
      throw Exception('Unable to save your session.');
    }
  }

  Future<Map<String, dynamic>?> getSession() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final bool isLoggedIn =
          preferences.getBool(AppConstants.sessionIsLoggedInKey) ?? false;
      final int? userId = preferences.getInt(AppConstants.sessionUserIdKey);
      final String? email = preferences.getString(AppConstants.sessionEmailKey);

      if (!isLoggedIn || userId == null || email == null) {
        return null;
      }

      return <String, dynamic>{
        'userId': userId,
        'email': email,
      };
    } catch (_) {
      throw Exception('Unable to restore your session.');
    }
  }

  Future<void> clearSession() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.remove(AppConstants.sessionIsLoggedInKey);
      await preferences.remove(AppConstants.sessionUserIdKey);
      await preferences.remove(AppConstants.sessionEmailKey);
    } catch (_) {
      throw Exception('Unable to clear your session.');
    }
  }
}
