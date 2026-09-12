import '../constants/app_strings.dart';

class AppValidators {
  AppValidators._();

  static const int PHONE_LENGTH = 10;
  static const int PINCODE_LENGTH = 6;
  static const int GST_LENGTH = 15;

  static String? requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? phoneNumber(String? value, {bool isRequired = true}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired ? AppStrings.CLIENT_VALIDATION_PHONE_REQUIRED : null;
    }
    if (trimmed.length != PHONE_LENGTH) {
      return AppStrings.CLIENT_VALIDATION_PHONE_INVALID;
    }
    return null;
  }

  static String? pincode(String? value, {bool isRequired = false}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired ? AppStrings.CLIENT_VALIDATION_PINCODE : null;
    }
    if (trimmed.length != PINCODE_LENGTH) {
      return AppStrings.CLIENT_VALIDATION_PINCODE;
    }
    return null;
  }

  static String? gstNumber(String? value, {bool isRequired = true}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired ? AppStrings.CLIENT_VALIDATION_GST_REQUIRED : null;
    }
    if (trimmed.length != GST_LENGTH) {
      return AppStrings.CLIENT_VALIDATION_GST;
    }
    return null;
  }
}
