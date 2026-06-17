import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';
import '../models/user_model.dart';
import '../utils/password_utils.dart';
import 'database_service.dart';
import 'session_service.dart';

class AuthService {
  static const String _duplicateEmailMessage =
      'An account already exists with this email.';
  static const String _invalidCredentialsMessage =
      'Invalid email or password.';
  static const String _invalidNameMessage =
      'Please enter your name.';
  static const String _invalidEmailMessage =
      'Please enter a valid email address.';
  static const String _invalidPasswordMessage =
      'Password must be at least 6 characters long.';

  AuthService({
    DatabaseService? databaseService,
    SessionService? sessionService,
  })  : _databaseService = databaseService ?? DatabaseService.instance,
        _sessionService = sessionService ?? const SessionService();

  final DatabaseService _databaseService;
  final SessionService _sessionService;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final String normalizedName = name.trim();
      final String normalizedEmail = _normalizeEmail(email);

      _validateRegistrationInput(
        name: normalizedName,
        email: normalizedEmail,
        password: password,
      );

      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> existingUsers = await db.query(
        AppConstants.usersTable,
        where: 'email = ?',
        whereArgs: <Object>[normalizedEmail],
        limit: 1,
      );

      if (existingUsers.isNotEmpty) {
        throw Exception(_duplicateEmailMessage);
      }

      final UserModel user = UserModel(
        name: normalizedName,
        email: normalizedEmail,
        passwordHash: PasswordUtils.hashPassword(password),
        profileImagePath: '',
        createdAt: DateTime.now(),
      );

      final int userId = await db.insert(AppConstants.usersTable, user.toMap());
      await _sessionService.saveSession(userId: userId, email: user.email);

      return UserModel(
        id: userId,
        name: user.name,
        email: user.email,
        passwordHash: user.passwordHash,
        profileImagePath: user.profileImagePath,
        createdAt: user.createdAt,
      );
    } catch (e) {
      if (_isKnownMessage(
        e,
        <String>[
          _duplicateEmailMessage,
          _invalidNameMessage,
          _invalidEmailMessage,
          _invalidPasswordMessage,
        ],
      )) {
        rethrow;
      }
      throw Exception('Unable to create your account.');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final String normalizedEmail = _normalizeEmail(email);
      _validateLoginInput(
        email: normalizedEmail,
        password: password,
      );

      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> users = await db.query(
        AppConstants.usersTable,
        where: 'email = ?',
        whereArgs: <Object>[normalizedEmail],
        limit: 1,
      );

      if (users.isEmpty) {
        throw Exception(_invalidCredentialsMessage);
      }

      final UserModel user = UserModel.fromMap(users.first);
      final String passwordHash = PasswordUtils.hashPassword(password);

      if (user.passwordHash != passwordHash) {
        throw Exception(_invalidCredentialsMessage);
      }

      await _sessionService.saveSession(
        userId: user.id!,
        email: user.email,
      );
      return user;
    } catch (e) {
      if (_isKnownMessage(
        e,
        <String>[
          _invalidCredentialsMessage,
          _invalidEmailMessage,
          _invalidPasswordMessage,
        ],
      )) {
        rethrow;
      }
      throw Exception('Unable to log you in.');
    }
  }

  Future<UserModel?> tryAutoLogin() async {
    try {
      final Map<String, dynamic>? session = await _sessionService.getSession();
      if (session == null) {
        return null;
      }

      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> users = await db.query(
        AppConstants.usersTable,
        where: 'id = ? AND email = ?',
        whereArgs: <Object>[session['userId'] as int, session['email'] as String],
        limit: 1,
      );

      if (users.isEmpty) {
        await _sessionService.clearSession();
        return null;
      }

      return UserModel.fromMap(users.first);
    } catch (_) {
      throw Exception('Unable to restore your account session.');
    }
  }

  Future<void> logout() async {
    try {
      await _sessionService.clearSession();
    } catch (_) {
      throw Exception('Unable to log out right now.');
    }
  }

  Future<UserModel> updateProfileImage({
    required int userId,
    required String imagePath,
  }) async {
    try {
      final Database db = await _databaseService.database;
      final int updatedRows = await db.update(
        AppConstants.usersTable,
        <String, Object>{
          'profile_image_path': imagePath.trim(),
        },
        where: 'id = ?',
        whereArgs: <Object>[userId],
      );

      if (updatedRows == 0) {
        throw Exception('User account not found.');
      }

      final List<Map<String, dynamic>> users = await db.query(
        AppConstants.usersTable,
        where: 'id = ?',
        whereArgs: <Object>[userId],
        limit: 1,
      );

      if (users.isEmpty) {
        throw Exception('User account not found.');
      }

      return UserModel.fromMap(users.first);
    } catch (e) {
      if (e is Exception && e.toString().contains('User account not found.')) {
        rethrow;
      }
      throw Exception('Unable to update your profile photo.');
    }
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  void _validateRegistrationInput({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.isEmpty) {
      throw Exception(_invalidNameMessage);
    }
    _validateEmail(email);
    _validatePassword(password);
  }

  void _validateLoginInput({
    required String email,
    required String password,
  }) {
    _validateEmail(email);
    _validatePassword(password);
  }

  void _validateEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      throw Exception(_invalidEmailMessage);
    }
  }

  void _validatePassword(String password) {
    if (password.trim().length < 6) {
      throw Exception(_invalidPasswordMessage);
    }
  }

  bool _isKnownMessage(Object error, List<String> messages) {
    if (error is! Exception) {
      return false;
    }

    final String normalizedError = error.toString();
    return messages.any(normalizedError.contains);
  }
}
