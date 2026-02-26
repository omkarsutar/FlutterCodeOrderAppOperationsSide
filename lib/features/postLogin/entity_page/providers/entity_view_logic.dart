import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/utils/date_utils.dart';

enum EntityViewFieldType { text, photo, phone, location, switchField, date }

class ProcessedEntityField {
  final String name;
  final String label;
  final dynamic rawValue;
  final String displayValue;
  final EntityViewFieldType type;
  final String? actionUrl;

  ProcessedEntityField({
    required this.name,
    required this.label,
    required this.rawValue,
    required this.displayValue,
    required this.type,
    this.actionUrl,
  });
}

class EntityViewLogic {
  static bool isPhoneField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('mobile') ||
        lowerName.contains('phone') ||
        lowerName.contains('contact');
  }

  static bool isLocationUrlField(String fieldName, String? value) {
    final lowerName = fieldName.toLowerCase();
    final isLocationField =
        lowerName.contains('location') || lowerName.contains('map');
    final isGoogleMapsUrl = value?.contains('google.com/maps') ?? false;
    return isLocationField || isGoogleMapsUrl;
  }

  static bool isPhotoField(String fieldName, dynamic value) {
    if (value == null) return false;
    final valStr = value.toString().trim().toLowerCase();
    if (valStr.isEmpty) return false;

    if (!(valStr.startsWith('http://') || valStr.startsWith('https://'))) {
      return false;
    }

    final lowerFieldName = fieldName.toLowerCase();
    final isPhotoFieldName =
        lowerFieldName.contains('photo') || lowerFieldName.contains('image');
    final hasImageExtension =
        valStr.endsWith('.jpg') ||
        valStr.endsWith('.jpeg') ||
        valStr.endsWith('.png') ||
        valStr.endsWith('.gif') ||
        valStr.endsWith('.webp');

    if (valStr.contains('google.com/maps') ||
        valStr.contains('location') ||
        valStr.contains('place')) {
      return hasImageExtension;
    }

    return isPhotoFieldName || hasImageExtension;
  }

  static String formatDateLikeField(FieldConfig field, dynamic value) {
    if (value == null) return '';
    DateTime? dt;

    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }

    if (dt != null) {
      return formatTimestamp(dt);
    }

    final lowerName = field.name.toLowerCase();
    final looksLikeDateField =
        lowerName.endsWith('_at') || lowerName.contains('date');
    if (looksLikeDateField && value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return formatTimestamp(parsed);
      }
    }

    return value.toString();
  }

  static Future<void> launchUrlExternally(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static Future<void> launchPhone(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanNumber');
      await launchUrl(uri);
    } catch (_) {}
  }

  static ProcessedEntityField processField<T>({
    required FieldConfig field,
    required dynamic value,
    required EntityAdapter<T> adapter,
    required T entity,
  }) {
    final fieldName = field.name;
    final valStr = value?.toString() ?? '';

    EntityViewFieldType type = EntityViewFieldType.text;
    String? actionUrl;
    String displayValue = '';

    if (isPhotoField(fieldName, value)) {
      type = EntityViewFieldType.photo;
      actionUrl = valStr.trim();
      displayValue = actionUrl;
    } else if (isPhoneField(fieldName)) {
      type = EntityViewFieldType.phone;
      displayValue = valStr;
    } else if (isLocationUrlField(fieldName, valStr)) {
      type = EntityViewFieldType.location;
      actionUrl = valStr;
      displayValue = 'Open in Maps';
    } else if (field.type == FieldType.switchField) {
      type = EntityViewFieldType.switchField;
      displayValue = value == true ? 'Yes' : 'No';
    } else {
      displayValue = formatDateLikeField(field, value);

      // Handle prefix/suffix
      if (field.prefix != null) {
        displayValue = '${field.prefix}$displayValue';
      }
      if (field.suffix != null) {
        displayValue = '$displayValue${field.suffix}';
      }
    }

    return ProcessedEntityField(
      name: fieldName,
      label: field.label,
      rawValue: value,
      displayValue: displayValue,
      type: type,
      actionUrl: actionUrl,
    );
  }
}
