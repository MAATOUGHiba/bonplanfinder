import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordUtils {
  const PasswordUtils._();

  static String hashPassword(String password) {
    final List<int> bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
