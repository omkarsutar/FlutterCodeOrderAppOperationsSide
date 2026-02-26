import '../../../../core/config/field_config.dart';
import '../../../../core/validators/form_validators.dart';

class EntityFormLogic {
  /// Builds a combined validator for a given field configuration
  static String? Function(String?)? buildValidator(FieldConfig field) {
    final validators = <String? Function(String?)>[];

    if (field.required) {
      validators.add(
        FormValidators.required(
          message: 'Please enter ${field.label.toLowerCase()}',
        ),
      );
    }

    if (field.maxLength != null) {
      validators.add(
        FormValidators.maxLength(
          field.maxLength!,
          message: '${field.label} must be under ${field.maxLength} characters',
        ),
      );
    }

    return validators.isEmpty ? null : FormValidators.combine(validators);
  }

  /// Decides which field UI type to use based on configuration
  /// This can be expanded if we need more complex logic for picking field types
  static FieldType getEffectiveFieldType(FieldConfig field) {
    return field.type;
  }
}
