// Common reusable form validators for SavourAI

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Name is required';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

String? validateConfirmPassword(String? value, String? password) {
  if (value == null || value.isEmpty) {
    return 'Confirm password is required';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

// Validates that the reminder date is not null and is in the future.
String? validateReminderDate(DateTime? value) {
  if (value == null) {
    return 'Please select a reminder date and time';
  }
  if (value.isBefore(DateTime.now())) {
    return 'Reminder must be set for a future date and time';
  }
  return null;
}

/// Validates that the cookbook name is not empty and not too long.
String? validateCookbookName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Cookbook name is required';
  }
  if (value.trim().length > 50) {
    return 'Cookbook name must be less than 50 characters';
  }
  return null;
}
