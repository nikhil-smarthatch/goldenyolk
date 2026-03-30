class Validators {
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveInteger(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? nonNegativeInteger(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? positiveDouble(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? nonNegativeDouble(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? maxValue(String? value, int max, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return null;
    }
    if (number > max) {
      return '$fieldName cannot exceed $max';
    }
    return null;
  }

  static String? dateNotInFuture(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }
}
