import 'package:intl/intl.dart';

class AppDateUtils {
  const AppDateUtils._();

  static String formatDateTime(DateTime value) {
    return DateFormat('MMM d, yyyy • HH:mm').format(value);
  }
}
