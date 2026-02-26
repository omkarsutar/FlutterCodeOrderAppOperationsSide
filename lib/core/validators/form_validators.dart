import 'package:flutter/material.dart';

class FormValidators {
  // Combine multiple validators into one
  static FormFieldValidator<String> combine(
    List<FormFieldValidator<String>> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result; // stop at first error
      }
      return null;
    };
  }

  static FormFieldValidator<String> required({
    String message = 'This field is required',
  }) {
    return (String? value) {
      if (value?.isEmpty ?? true) return message;
      return null;
    };
  }

  static FormFieldValidator<String> email({
    String message = 'Enter a valid email',
  }) {
    return (String? value) {
      if (value?.isEmpty ?? true) return 'Email is required';
      const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      if (!RegExp(pattern).hasMatch(value!)) return message;
      return null;
    };
  }

  static FormFieldValidator<String> minLength(int min, {String? message}) {
    return (String? value) {
      if (value?.isEmpty ?? true) return 'This field is required';
      if (value!.length < min)
        return message ?? 'Minimum $min characters required';
      return null;
    };
  }

  static FormFieldValidator<String> maxLength(int max, {String? message}) {
    return (String? value) {
      if (value != null && value.length > max) {
        return message ?? 'Must be under $max characters';
      }
      return null;
    };
  }

  static FormFieldValidator<String> number({
    String message = 'Enter a valid number',
  }) {
    return (String? value) {
      if (value?.isEmpty ?? true) return 'This field is required';
      if (double.tryParse(value!) == null) return message;
      return null;
    };
  }

  static FormFieldValidator<String> uuid({
    String message = 'Invalid ID format',
  }) {
    return (String? value) {
      if (value?.isEmpty ?? true) return 'ID is required';
      const pattern =
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
      if (!RegExp(pattern, caseSensitive: false).hasMatch(value!))
        return message;
      return null;
    };
  }
}
