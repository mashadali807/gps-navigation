import 'package:flutter/material.dart';
import 'package:smart_route/core/utills/validators.dart';
import '../constants/app_constants.dart';

class Validators {
  // ============ EMAIL VALIDATION ============

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }

    final trimmed = value.trim();
    if (!AppConstants.emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate email with additional checks
  static String? validateEmailStrict(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }

    final trimmed = value.trim();

    // Check format
    if (!AppConstants.emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address (e.g., name@domain.com)';
    }

    // Check for common disposable email domains
    final disposableDomains = [
      'tempmail.com',
      'throwaway.com',
      'guerrillamail.com',
      'mailinator.com',
      'yopmail.com',
      '10minutemail.com',
    ];

    final domain = trimmed.split('@').last.toLowerCase();
    if (disposableDomains.contains(domain)) {
      return 'Please use a permanent email address';
    }

    return null;
  }

  // ============ PASSWORD VALIDATION ============

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validate password with strength checks
  static String? validatePasswordStrong(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = value.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!hasDigits) {
      return 'Password must contain at least one number';
    }
    if (!hasSpecialCharacters) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ============ PHONE VALIDATION ============

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final trimmed = value.trim();
    if (!AppConstants.phoneRegex.hasMatch(trimmed)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate phone with country code
  static String? validatePhoneWithCountry(String? value, String countryCode) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final fullNumber = '$countryCode${value.trim()}';
    if (!AppConstants.phoneRegex.hasMatch(fullNumber)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // ============ NAME VALIDATION ============

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 50) {
      return 'Name cannot exceed 50 characters';
    }

    if (!RegExp(r'''^[a-zA-Z\s\-\.\']+$''').hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, periods, and apostrophes';
    }
  }

  /// Validate full name (first and last)
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }

    final trimmed = value.trim();
    final parts = trimmed.split(' ');

    if (parts.length < 2) {
      return 'Please enter your full name (first and last)';
    }

    if (parts.any((part) => part.length < 2)) {
      return 'Each name part must be at least 2 characters';
    }

    return null;
  }

  // ============ ADDRESS VALIDATION ============

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < 5) {
      return 'Address must be at least 5 characters';
    }

    if (trimmed.length > 200) {
      return 'Address cannot exceed 200 characters';
    }

    return null;
  }

  /// Validate city
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'City must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(trimmed)) {
      return 'City can only contain letters, spaces, hyphens, and periods';
    }

    return null;
  }

  /// Validate postal code
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Postal code must be at least 3 characters';
    }

    if (trimmed.length > 10) {
      return 'Postal code cannot exceed 10 characters';
    }

    return null;
  }

  // ============ URL VALIDATION ============

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    final trimmed = value.trim();
    // Use a simple URL validation since isValidUrl might not exist
    try {
      Uri.parse(trimmed);
      return null;
    } catch (_) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }
  }

  /// Validate URL (optional)
  static String? validateUrlOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final trimmed = value.trim();
    try {
      Uri.parse(trimmed);
      return null;
    } catch (_) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }
  }

  // ============ NUMBER VALIDATION ============

  /// Validate number
  static String? validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }

    final trimmed = value.trim();
    final number = double.tryParse(trimmed);

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (min != null && number < min) {
      return 'Number must be at least $min';
    }

    if (max != null && number > max) {
      return 'Number must be at most $max';
    }

    return null;
  }

  /// Validate integer
  static String? validateInteger(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }

    final trimmed = value.trim();
    final number = int.tryParse(trimmed);

    if (number == null) {
      return 'Please enter a valid whole number';
    }

    if (min != null && number < min) {
      return 'Number must be at least $min';
    }

    if (max != null && number > max) {
      return 'Number must be at most $max';
    }

    return null;
  }

  // ============ DATE VALIDATION ============

  /// Validate date
  static String? validateDate(
    String? value, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    final trimmed = value.trim();
    final date = DateTime.tryParse(trimmed);

    if (date == null) {
      return 'Please enter a valid date (YYYY-MM-DD)';
    }

    if (minDate != null && date.isBefore(minDate)) {
      return 'Date must be on or after ${_formatDate(minDate)}';
    }

    if (maxDate != null && date.isAfter(maxDate)) {
      return 'Date must be on or before ${_formatDate(maxDate)}';
    }

    return null;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ============ REQUIRED FIELD VALIDATION ============

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }

    return null;
  }

  /// Validate required dropdown
  static String? validateDropdown<T>(T? value, {String? fieldName}) {
    if (value == null) {
      return fieldName != null
          ? 'Please select $fieldName'
          : 'Please select an option';
    }
    return null;
  }

  // ============ EMAIL/PASSWORD COMBINATION ============

  /// Validate login credentials
  static String? validateLogin(String? email, String? password) {
    final emailError = validateEmail(email);
    if (emailError != null) return emailError;

    final passwordError = validatePassword(password);
    if (passwordError != null) return passwordError;

    return null;
  }

  /// Validate registration
  static String? validateRegistration({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return nameError;

    final emailError = validateEmail(email);
    if (emailError != null) return emailError;

    final passwordError = validatePasswordStrong(password);
    if (passwordError != null) return passwordError;

    final confirmError = validateConfirmPassword(confirmPassword, password);
    if (confirmError != null) return confirmError;

    return null;
  }

  // ============ CUSTOM VALIDATION ============

  /// Create custom validator
  static String? Function(String?)? customValidator({
    required bool Function(String?) predicate,
    required String errorMessage,
  }) {
    return (String? value) {
      if (value == null) return errorMessage;
      if (predicate(value)) return null;
      return errorMessage;
    };
  }

  /// Validate with multiple conditions
  static String? Function(String?)? composeValidators(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  // ============ FIELD GROUP VALIDATION ============

  /// Validate multiple fields
  static Map<String, String?> validateFields(
    Map<String, String?> fields,
    Map<String, String? Function(String?)> validators,
  ) {
    final errors = <String, String?>{};
    for (final entry in fields.entries) {
      final field = entry.key;
      final value = entry.value;
      final validator = validators[field];
      if (validator != null) {
        errors[field] = validator(value);
      }
    }
    return errors;
  }

  /// Check if field group has errors
  static bool hasErrors(Map<String, String?> errors) {
    return errors.values.any((error) => error != null);
  }

  /// Get first error from field group
  static String? getFirstError(Map<String, String?> errors) {
    for (final error in errors.values) {
      if (error != null) return error;
    }
    return null;
  }

  // ============ CONVENIENCE METHODS ============

  /// Check if value is empty
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Check if value is not empty
  static bool isNotEmpty(String? value) {
    return !isEmpty(value);
  }

  /// Clean and trim value
  static String? cleanValue(String? value) {
    if (value == null) return null;
    return value.trim();
  }

  /// Sanitize input (remove special characters)
  static String sanitizeInput(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[^\w\s\-\.]'), '').trim();
  }

  // ============ Form Field Validation Functions ============

  /// Common form field validators
  static final FormFieldValidator<String> emailValidator = (value) =>
      validateEmail(value);
  static final FormFieldValidator<String> passwordValidator = (value) =>
      validatePassword(value);
  static final FormFieldValidator<String> nameValidator = (value) =>
      validateName(value);
  static final FormFieldValidator<String> phoneValidator = (value) =>
      validatePhone(value);
  static final FormFieldValidator<String> requiredValidator = (value) =>
      validateRequired(value, fieldName: 'This field');
}

// ============ EXTENSIONS ============

/// Extension methods for validation on String
extension StringValidationExtension on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => Validators.isEmpty(this);

  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => Validators.isNotEmpty(this);

  /// Validate email
  String? get validateEmail => Validators.validateEmail(this);

  /// Validate password
  String? get validatePassword => Validators.validatePassword(this);

  /// Validate name
  String? get validateName => Validators.validateName(this);

  /// Validate phone
  String? get validatePhone => Validators.validatePhone(this);

  /// Validate required
  String? validateRequired({String? fieldName}) =>
      Validators.validateRequired(this, fieldName: fieldName);

  /// Sanitize string
  String get sanitized => Validators.sanitizeInput(this);

  /// Clean string (trim)
  String? get cleaned => Validators.cleanValue(this);
}

/// Extension methods for validation on TextEditingController
extension TextEditingControllerValidationExtension on TextEditingController {
  /// Get text value or empty string
  String get textOrEmpty => text ?? '';

  /// Validate email
  String? get validateEmail => Validators.validateEmail(text);

  /// Validate password
  String? get validatePassword => Validators.validatePassword(text);

  /// Validate name
  String? get validateName => Validators.validateName(text);

  /// Validate phone
  String? get validatePhone => Validators.validatePhone(text);

  /// Validate required
  String? validateRequired({String? fieldName}) =>
      Validators.validateRequired(text, fieldName: fieldName);
}
