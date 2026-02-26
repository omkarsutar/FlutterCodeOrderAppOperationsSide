import '../services/entity_service.dart';
import 'dropdown_source.dart';

class ForeignKeyConfig {
  final String table;
  final String idColumn;
  final String labelColumn;
  final Future<List<Map<String, dynamic>>> Function(EntityService)?
  fetchDropdownItems;

  const ForeignKeyConfig({
    required this.table,
    required this.idColumn,
    required this.labelColumn,
    this.fetchDropdownItems,
  });
}

enum FieldType {
  text,
  textarea,
  switchField,
  dropdown,
  doubleField,
  intField,
  textField,
  integer,
  selector,
}

class FieldConfig {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final bool readOnly;
  final bool visibleInForm; // Show/hide in form pages
  final bool visibleInList; // Show/hide in list pages
  final int? maxLength;
  final DropdownSource? dropdownSource; // unified type
  final List<String>? dropdownOptions;
  final String? prefix; // e.g. '₹ ' for currency fields
  final String? suffix; // e.g. ' kg' for weight fields

  FieldConfig({
    required this.name,
    required this.label,
    this.type = FieldType.text,
    this.required = false,
    this.readOnly = false,
    this.visibleInForm = true,
    this.visibleInList = true,
    this.maxLength,
    this.dropdownSource,
    this.dropdownOptions,
    this.prefix,
    this.suffix,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      type: FieldType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => FieldType.text,
      ),
      required: json['required'] as bool? ?? false,
      readOnly: json['readOnly'] as bool? ?? false,
      visibleInForm: json['visibleInForm'] as bool? ?? true,
      visibleInList: json['visibleInList'] as bool? ?? true,
      maxLength: json['maxLength'] as int?,
      dropdownOptions: (json['dropdownOptions'] as List?)
          ?.map((e) => e as String)
          .toList(),
      dropdownSource: json['dropdownSource'] != null
          ? DropdownSource.fromJson(json['dropdownSource'])
          : null,
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type.name,
      'required': required,
      'readOnly': readOnly,
      'visibleInForm': visibleInForm,
      'visibleInList': visibleInList,
      if (maxLength != null) 'maxLength': maxLength,
      if (dropdownOptions != null) 'dropdownOptions': dropdownOptions,
      if (dropdownSource != null) 'dropdownSource': dropdownSource!.toJson(),
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
    };
  }
}
