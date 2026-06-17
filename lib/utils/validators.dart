class Validators {
  const Validators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name.';
    }
    if (value.trim().length < 2) {
      return 'Name must contain at least 2 characters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }

    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  static String? validateReviewComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your review.';
    }
    if (value.trim().length < 5) {
      return 'Review must contain at least 5 characters.';
    }
    return null;
  }

  static String? validateRequiredPlaceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a place name.';
    }
    if (value.trim().length > 80) {
      return 'Place name must be 80 characters or less.';
    }
    return null;
  }

  static String? validateRequiredAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an address.';
    }
    if (value.trim().length > 180) {
      return 'Address must be 180 characters or less.';
    }
    return null;
  }

  static String? validateOptionalDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Description must be 500 characters or less.';
    }
    return null;
  }

  static String? validateOptionalCuisine(String? value) {
    if (value != null && value.trim().length > 80) {
      return 'Cuisine must be 80 characters or less.';
    }
    return null;
  }

  static String? validateOptionalPhone(String? value) {
    if (value != null && value.trim().length > 30) {
      return 'Phone number must be 30 characters or less.';
    }
    return null;
  }

  static String? validateOptionalLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final double? latitude = double.tryParse(value.trim());
    if (latitude == null || latitude < -90 || latitude > 90) {
      return 'Latitude must be between -90 and 90.';
    }
    return null;
  }

  static String? validateOptionalLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final double? longitude = double.tryParse(value.trim());
    if (longitude == null || longitude < -180 || longitude > 180) {
      return 'Longitude must be between -180 and 180.';
    }
    return null;
  }
}
