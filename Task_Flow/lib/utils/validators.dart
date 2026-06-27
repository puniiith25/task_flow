class Validators {
  // Common list of disposable/temporary email domains to prevent fake signups
  static const List<String> _disposableDomains = [
    'mailinator.com',
    'yopmail.com',
    'tempmail.com',
    'temp-mail.org',
    'guerrillamail.com',
    'sharklasers.com',
    'dispostable.com',
    '10minutemail.com',
    'getairmail.com',
    'throwawaymail.com',
  ];

  /// Validates if an email is formatted correctly and is not from a disposable domain
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final email = value.trim().toLowerCase();
    
    // Regular expression for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    // Extract domain and verify against disposable list
    final parts = email.split('@');
    if (parts.length == 2) {
      final domain = parts[1];
      if (_disposableDomains.contains(domain)) {
        return 'Temporary/disposable emails are not allowed';
      }
    }
    
    return null;
  }

  /// Validates password strength (minimum 8 characters, upper/lower/number/special)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigits = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

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

  /// Simple password validation for login (non-empty check only)
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  /// Validates that password and confirm password fields match
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}
