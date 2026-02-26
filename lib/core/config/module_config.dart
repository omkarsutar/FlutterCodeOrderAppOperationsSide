import 'dart:convert';
import 'package:flutter/services.dart';

import 'field_config.dart';
import '../models/entity_meta.dart';
import 'dropdown_source.dart';

/// Configuration for a module loaded from JSON

class ModuleConfig {
  final String moduleName;
  final EntityMeta entityMeta;
  final TableConfig table;
  final RouteConfig routes;
  final ListPageConfig? listPage;
  final List<FieldConfig> fields;

  ModuleConfig({
    required this.moduleName,
    required this.entityMeta,
    required this.table,
    required this.routes,
    this.listPage,
    required this.fields,
  });

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      moduleName: json['moduleName'] as String,
      entityMeta: EntityMetaJson.fromJson(json['entityMeta']),
      table: TableConfig.fromJson(json['table']),
      routes: RouteConfig.fromJson(json['routes']),
      listPage: json['listPage'] != null
          ? ListPageConfig.fromJson(json['listPage'])
          : null,
      fields: (json['fields'] as List)
          .map((f) => FieldConfig.fromJson(f))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleName': moduleName,
      'entityMeta': entityMeta.toJson(),
      'table': table.toJson(),
      'routes': routes.toJson(),
      if (listPage != null) 'listPage': listPage!.toJson(),
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  static Future<ModuleConfig> loadFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return ModuleConfig.fromJson(jsonMap);
  }
}

// TableConfig, RouteConfig, ListPageConfig, EntityMetaJson remain unchanged

/// Table configuration
class TableConfig {
  final String name;
  final String? viewName;
  final String idField;
  final String? timestampField;

  TableConfig({
    required this.name,
    this.viewName,
    required this.idField,
    this.timestampField,
  });

  factory TableConfig.fromJson(Map<String, dynamic> json) {
    return TableConfig(
      name: json['name'] as String,
      viewName: json['viewName'] as String?,
      idField: json['idField'] as String,
      timestampField: json['timestampField'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (viewName != null) 'viewName': viewName,
      'idField': idField,
      if (timestampField != null) 'timestampField': timestampField,
    };
  }
}

/// Route configuration
class RouteConfig {
  final String basePath;
  final String listRouteName;
  final String newRouteName;
  final String editRouteName;
  final String viewRouteName;

  RouteConfig({
    required this.basePath,
    required this.listRouteName,
    required this.newRouteName,
    required this.editRouteName,
    required this.viewRouteName,
  });

  factory RouteConfig.fromJson(Map<String, dynamic> json) {
    return RouteConfig(
      basePath: json['basePath'] as String,
      listRouteName: json['listRouteName'] as String,
      newRouteName: json['newRouteName'] as String,
      editRouteName: json['editRouteName'] as String,
      viewRouteName: json['viewRouteName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePath': basePath,
      'listRouteName': listRouteName,
      'newRouteName': newRouteName,
      'editRouteName': editRouteName,
      'viewRouteName': viewRouteName,
    };
  }

  // Generate route paths
  String get listPath => basePath;
  String get newPath => '$basePath/new';
  String get editPath => '$basePath/edit/:id';
  String get viewPath => '$basePath/:id';

  String editRoute(String id) => '$basePath/edit/$id';
  String viewRoute(String id) => '$basePath/$id';
}

/// Sorting configuration for list page
class SortingConfig {
  final String field;
  final bool sortAscending;

  SortingConfig({required this.field, required this.sortAscending});

  factory SortingConfig.fromJson(Map<String, dynamic> json) {
    return SortingConfig(
      field: json['field'] as String,
      sortAscending: json['sortAscending'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'field': field, 'sortAscending': sortAscending};
  }
}

/// List page configuration
class ListPageConfig {
  final List<String> searchFields;
  final SortingConfig? sorting;

  ListPageConfig({this.searchFields = const [], this.sorting});

  factory ListPageConfig.fromJson(Map<String, dynamic> json) {
    return ListPageConfig(
      searchFields:
          (json['searchFields'] as List?)?.map((e) => e as String).toList() ??
          [],
      sorting: json['sorting'] != null
          ? SortingConfig.fromJson(json['sorting'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchFields': searchFields,
      if (sorting != null) 'sorting': sorting!.toJson(),
    };
  }
}

// Extension to add fromJson/toJson to EntityMeta
extension EntityMetaJson on EntityMeta {
  static EntityMeta fromJson(Map<String, dynamic> json) {
    return EntityMeta(
      entityName: json['entityName'] as String,
      entityNameLower:
          json['entityNameLower'] as String? ??
          (json['entityName'] as String).toLowerCase(),
      entityNamePlural: json['entityNamePlural'] as String,
      entityNamePluralLower:
          json['entityNamePluralLower'] as String? ??
          (json['entityNamePlural'] as String).toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityName': entityName,
      'entityNameLower': entityNameLower,
      'entityNamePlural': entityNamePlural,
      'entityNamePluralLower': entityNamePluralLower,
    };
  }
}

// Extension to add fromJson/toJson to FieldConfig
extension FieldConfigJson on FieldConfig {
  static FieldConfig fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      type: _parseFieldType(json['type'] as String),
      required: json['required'] as bool? ?? false,
      readOnly: json['readOnly'] as bool? ?? false,
      visibleInList: json['visibleInList'] as bool? ?? true,
      visibleInForm: json['visibleInForm'] as bool? ?? true,
      maxLength: json['maxLength'] as int?,
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
      dropdownOptions: (json['dropdownOptions'] as List?)
          ?.map((e) => e as String)
          .toList(),
      dropdownSource: json['dropdownSource'] != null
          ? DropdownSource.fromJson(json['dropdownSource'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type.name,
      'required': required,
      'readOnly': readOnly,
      'visibleInList': visibleInList,
      'visibleInForm': visibleInForm,
      if (maxLength != null) 'maxLength': maxLength,
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
      if (dropdownOptions != null) 'dropdownOptions': dropdownOptions,
      if (dropdownSource != null) 'dropdownSource': dropdownSource!.toJson(),
    };
  }

  static FieldType _parseFieldType(String typeStr) {
    return FieldType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FieldType.text,
    );
  }
}
