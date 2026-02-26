import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';

class GenericFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final Map<String, List<Map<String, dynamic>>> dropdownOptions;
  final Map<String, dynamic>? initialData;

  const GenericFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.dropdownOptions = const {},
    this.initialData,
  });

  GenericFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    Map<String, List<Map<String, dynamic>>>? dropdownOptions,
    Map<String, dynamic>? initialData,
  }) {
    return GenericFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable update
      isSuccess: isSuccess ?? this.isSuccess,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
      initialData: initialData ?? this.initialData,
    );
  }
}

class GenericFormController
    extends AutoDisposeFamilyNotifier<GenericFormState, String> {
  @override
  GenericFormState build(String arg) {
    return const GenericFormState();
  }

  Future<void> loadDropdownOptions(List<FieldConfig> fieldConfigs) async {
    final newOptions = Map<String, List<Map<String, dynamic>>>.from(
      state.dropdownOptions,
    );

    for (var field in fieldConfigs) {
      if (field.type != FieldType.dropdown) continue;
      if (field.dropdownSource == null) continue;

      try {
        final source = field.dropdownSource!;
        final data = await Supabase.instance.client
            .from(source.table)
            .select()
            .order(source.labelKey, ascending: true);

        newOptions[field.name] = List<Map<String, dynamic>>.from(data);
      } catch (e) {
        debugPrint('Error loading options for ${field.name}: $e');
      }
    }

    state = state.copyWith(dropdownOptions: newOptions);
  }

  Future<void> loadEntity<T>({
    required String entityId,
    required AutoDisposeFutureProviderFamily<T?, String> entityByIdProvider,
    required Provider<EntityAdapter<T>> adapterProvider,
    required List<FieldConfig> fieldConfigs,
    Map<String, dynamic> Function(T entity)? initialValuesMapper,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entity = await ref.read(entityByIdProvider(entityId).future);

      if (entity != null) {
        Map<String, dynamic> values;

        if (initialValuesMapper != null) {
          values = initialValuesMapper(entity);
        } else {
          final adapter = ref.read(adapterProvider);
          values = {};
          for (var field in fieldConfigs) {
            if (!field.visibleInForm) continue;

            final val = adapter.getFieldValue(entity, field.name);
            if (val != null) {
              if (field.type == FieldType.doubleField ||
                  field.type == FieldType.intField ||
                  field.type == FieldType.integer) {
                values[field.name] = val.toString();
              } else {
                values[field.name] = val;
              }
            }

            // Also fetch labels for dropdown/selector fields if available
            if (field.type == FieldType.dropdown ||
                field.type == FieldType.selector) {
              final label = adapter.getLabelValue(entity, field.name);
              if (label != null) {
                values['${field.name}_label'] = label;
              }
            }
          }
        }
        debugPrint('GenericFormController: Loaded initialData: $values');
        state = state.copyWith(isLoading: false, initialData: values);
      } else {
        state = state.copyWith(isLoading: false, error: 'Entity not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveEntity({
    required Future<bool> Function(WidgetRef, Map<String, dynamic>, String?)
    onSave,
    required Map<String, dynamic> fieldValues,
    String? entityId,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final success = await onSave(ref, fieldValues, entityId);
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to save');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final genericFormControllerProvider = NotifierProvider.autoDispose
    .family<GenericFormController, GenericFormState, String>(
      () => GenericFormController(),
    );
