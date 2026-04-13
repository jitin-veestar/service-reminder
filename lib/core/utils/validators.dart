abstract final class Validators {
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final valid = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!valid.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  // Phone is optional — only validates format when a value is provided.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final valid = RegExp(r'^\+?[\d\s\-]{7,15}$');
    if (!valid.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? name(String? value) => required(value, fieldName: 'Name');
}
