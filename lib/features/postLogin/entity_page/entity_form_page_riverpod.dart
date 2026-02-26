import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/field_config.dart';
import '../../../core/models/entity_meta.dart';
import '../../../core/services/entity_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/services/error_handler.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/providers/core_providers.dart';
import 'providers/entity_form_logic.dart';
import 'providers/generic_form_controller.dart';

/// Generic Riverpod version of Entity Form Page
/// Can be used for any entity type (Role, Note, etc.)
class EntityFormPageRiverpod<T> extends ConsumerStatefulWidget {
  final String? entityId;
  final EntityMeta entityMeta;
  final List<FieldConfig> fieldConfigs;
  final String listRouteName;
  final String rbacModule;

  // Riverpod providers
  final AutoDisposeFutureProviderFamily<T?, String> entityByIdProvider;
  final Provider<EntityAdapter<T>> adapterProvider;

  // Callbacks for entity-specific operations
  final Future<bool> Function(
    WidgetRef ref,
    Map<String, dynamic> fieldValues,
    String? entityId,
  )
  onSave;
  final Map<String, dynamic> Function(T entity)? initialValues;
  final Map<String, dynamic>? defaultValues;

  const EntityFormPageRiverpod({
    super.key,
    this.entityId,
    required this.entityMeta,
    required this.fieldConfigs,
    required this.listRouteName,
    required this.rbacModule,
    required this.entityByIdProvider,
    required this.adapterProvider,
    required this.onSave,
    this.initialValues,
    this.defaultValues,
  });

  @override
  ConsumerState<EntityFormPageRiverpod<T>> createState() =>
      _EntityFormPageRiverpodState<T>();
}

class _EntityFormPageRiverpodState<T>
    extends ConsumerState<EntityFormPageRiverpod<T>> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _switchValues = {};
  final Map<String, dynamic> _dropdownValues = {}; // Store selected IDs
  final Map<String, String> _selectorLabels =
      {}; // Store display labels for selectors

  // Track if we have initialized form data from remote entity
  bool _isDataLoaded = false;

  FocusNode? _firstFocusNode;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Defer controller calls until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(
        genericFormControllerProvider(widget.entityMeta.entityName).notifier,
      );

      // Load Options
      controller.loadDropdownOptions(widget.fieldConfigs);

      // Load Entity if editing
      if (widget.entityId != null) {
        controller.loadEntity(
          entityId: widget.entityId!,
          entityByIdProvider: widget.entityByIdProvider,
          adapterProvider: widget.adapterProvider,
          fieldConfigs: widget.fieldConfigs,
          initialValuesMapper: widget.initialValues,
        );
      }
    });
  }

  void _initializeControllers() {
    for (var field in widget.fieldConfigs) {
      // Only initialize controllers for fields visible in form
      if (!field.visibleInForm) continue;

      final defaultValue = widget.defaultValues?[field.name];

      if (field.type == FieldType.switchField) {
        _switchValues[field.name] = (defaultValue as bool?) ?? false;
      } else if (field.type == FieldType.dropdown) {
        if (defaultValue != null) {
          _dropdownValues[field.name] = defaultValue.toString();
        } else if (field.dropdownOptions != null &&
            field.dropdownOptions!.isNotEmpty) {
          _dropdownValues[field.name] = field.dropdownOptions!.first;
        }
        // Dropdown doesn't use TextEditingController in this implementation
      } else if (field.type == FieldType.selector) {
        if (defaultValue != null) {
          _dropdownValues[field.name] = defaultValue.toString();
          // We might not have the label yet if it's just a default ID
          _selectorLabels[field.name] = defaultValue.toString();
        }
      } else {
        _controllers[field.name] = TextEditingController(
          text: defaultValue?.toString(),
        );
      }
    }
    // Set first text field focus node
    if (_controllers.isNotEmpty) {
      _firstFocusNode = FocusNode();
    }
  }

  void _populateForm(Map<String, dynamic> values) {
    if (_isDataLoaded) return;

    for (var field in widget.fieldConfigs) {
      if (!field.visibleInForm) continue;

      final value = values[field.name];

      if (field.type == FieldType.switchField) {
        if (value != null) setState(() => _switchValues[field.name] = value);
      } else if (field.type == FieldType.dropdown ||
          field.type == FieldType.selector) {
        if (value != null) {
          setState(() {
            _dropdownValues[field.name] = value.toString();

            // Use the label provided in the map if available
            final label = values['${field.name}_label'];
            if (label != null) {
              _selectorLabels[field.name] = label.toString();
            } else {
              _selectorLabels[field.name] = value.toString();
            }
          });
        }
      } else if (value != null) {
        _controllers[field.name]?.text = value.toString();
      }
    }

    setState(() => _isDataLoaded = true);
  }

  Future<void> _onSavePressed(GenericFormController controller) async {
    if (!_formKey.currentState!.validate()) return;

    // Collect field values
    final fieldValues = <String, dynamic>{};
    for (var field in widget.fieldConfigs) {
      if (field.type == FieldType.switchField) {
        fieldValues[field.name] = _switchValues[field.name] ?? false;
      } else if (field.type == FieldType.dropdown ||
          field.type == FieldType.selector) {
        fieldValues[field.name] = _dropdownValues[field.name];
      } else {
        fieldValues[field.name] = _controllers[field.name]?.text;
      }
    }

    controller.saveEntity(
      onSave: widget.onSave,
      fieldValues: fieldValues,
      entityId: widget.entityId,
      ref: ref,
    );
  }

  /// Build form fields list, filtering by visibility and tracking first field
  List<Widget> _buildFormFields(
    Map<String, List<Map<String, dynamic>>> dropdownOptions,
  ) {
    final visibleFields = widget.fieldConfigs
        .where((field) => field.visibleInForm)
        .toList();

    if (visibleFields.isEmpty) {
      return [const SizedBox.shrink()];
    }

    final widgets = <Widget>[];
    for (int i = 0; i < visibleFields.length; i++) {
      widgets.add(
        _buildField(visibleFields[i], dropdownOptions, isFirst: i == 0),
      );
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _buildField(
    FieldConfig field,
    Map<String, List<Map<String, dynamic>>> dropdownOptions, {
    bool isFirst = false,
  }) {
    switch (field.type) {
      case FieldType.switchField:
        return _buildSwitchField(field);
      case FieldType.dropdown:
        return _buildDropdownField(field, dropdownOptions);
      case FieldType.selector:
        return _buildSelectorField(field);
      case FieldType.textarea:
        return _buildTextAreaField(field, isFirst: isFirst);
      case FieldType.text:
      default:
        return _buildTextField(field, isFirst: isFirst);
    }
  }

  Widget _buildTextField(FieldConfig field, {bool isFirst = false}) {
    return TextFormField(
      controller: _controllers[field.name],
      focusNode: isFirst ? _firstFocusNode : null,
      autofocus: isFirst && !field.readOnly,
      enabled: !field.readOnly,
      maxLength: field.maxLength,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        counterText: '',
        helperText: field.readOnly ? 'Read-only' : null,
      ),
      validator: EntityFormLogic.buildValidator(field),
    );
  }

  Widget _buildTextAreaField(FieldConfig field, {bool isFirst = false}) {
    return TextFormField(
      controller: _controllers[field.name],
      focusNode: isFirst ? _firstFocusNode : null,
      autofocus: isFirst && !field.readOnly,
      enabled: !field.readOnly,
      maxLines: 5,
      maxLength: field.maxLength,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        counterText: '',
        helperText: field.readOnly ? 'Read-only' : null,
      ),
      validator: EntityFormLogic.buildValidator(field),
    );
  }

  Widget _buildSwitchField(FieldConfig field) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.label, style: Theme.of(context).textTheme.titleMedium),
              if (field.readOnly)
                Text('Read-only', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Switch(
          value: _switchValues[field.name] ?? false,
          onChanged: field.readOnly
              ? null
              : (value) {
                  setState(() {
                    _switchValues[field.name] = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildSelectorField(FieldConfig field) {
    final theme = Theme.of(context);
    final currentValue = _dropdownValues[field.name];
    final currentLabel = _selectorLabels[field.name] ?? 'Select ${field.label}';

    return FormField<String>(
      initialValue: currentValue,
      validator: (value) =>
          EntityFormLogic.buildValidator(field)?.call(currentValue),
      builder: (FormFieldState<String> state) {
        return InkWell(
          onTap: field.readOnly
              ? null
              : () async {
                  final routeName = field.dropdownSource?.routeName;
                  if (routeName == null) {
                    SnackbarUtils.showError(
                      'No routeName defined for selector',
                    );
                    return;
                  }

                  final result = await context.pushNamed(
                    routeName,
                    queryParameters: {'selection': 'true'},
                  );

                  if (result != null && mounted) {
                    // We assume result is an entity object
                    // We need to extract the ID and Label using dropdownSource config
                    final valueKey = field.dropdownSource?.valueKey ?? 'id';
                    final labelKey = field.dropdownSource?.labelKey ?? 'name';

                    // Try to extract from result (could be a Map or Model object)
                    String? selectedId;
                    String? selectedLabel;

                    try {
                      // If it's a map or has a dynamic getter
                      if (result is Map) {
                        selectedId = result[valueKey]?.toString();
                        selectedLabel = result[labelKey]?.toString();
                      } else {
                        // Try to use reflection-like access or just assume it's a model
                        // For now, we'll try to use the adapter if we can find it
                        // But we don't know the type of the result here easily
                        // Let's assume the result is the entity and we can try to use its toMap or similar
                        // Most of our models have toMap()
                        final map = (result as dynamic).toMap();
                        selectedId = map[valueKey]?.toString();
                        selectedLabel = map[labelKey]?.toString();
                      }
                    } catch (e) {
                      debugPrint(
                        'Failed to extract values from selector result: $e',
                      );
                      // Fallback to string representation if extraction fails
                      selectedId = result.toString();
                      selectedLabel = result.toString();
                    }

                    if (selectedId != null) {
                      setState(() {
                        _dropdownValues[field.name] = selectedId;
                        _selectorLabels[field.name] =
                            selectedLabel ?? selectedId!;
                      });
                      state.didChange(selectedId);
                    }
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              errorText: state.errorText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: const Icon(Icons.search),
              helperText: field.readOnly ? 'Read-only' : null,
            ),
            child: Text(
              currentLabel,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: currentValue == null
                    ? theme.hintColor
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField(
    FieldConfig field,
    Map<String, List<Map<String, dynamic>>> dropdownOptions,
  ) {
    // Handle static dropdown options
    if (field.dropdownOptions != null) {
      final items = field.dropdownOptions!.map((option) {
        return DropdownMenuItem<String>(value: option, child: Text(option));
      }).toList();

      return DropdownButtonFormField<String>(
        value: _dropdownValues[field.name] ?? items.firstOrNull?.value,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _dropdownValues[field.name] = value;
            });
          }
        },
        validator: EntityFormLogic.buildValidator(field),
      );
    }

    // Dynamic Options from Controller State
    final options = dropdownOptions[field.name] ?? [];
    final currentValue = _dropdownValues[field.name];

    // If we have a current value but no options yet, show a disabled field with the current value
    if (currentValue != null && options.isEmpty) {
      return TextFormField(
        initialValue: currentValue,
        enabled: false,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
          helperText: 'Loading options...',
        ),
      );
    }

    // Decide which keys to use for value/label
    final valueKey = field.dropdownSource?.valueKey ?? 'id';
    final labelKey = field.dropdownSource?.labelKey ?? 'name';

    // Format options for DropdownMenuItem
    final items = options.map<DropdownMenuItem<String>>((opt) {
      final value = opt[valueKey]?.toString() ?? '';
      final label = opt[labelKey]?.toString() ?? 'Unnamed';
      return DropdownMenuItem<String>(value: value, child: Text(label));
    }).toList();

    // Ensure the currentValue exists in items
    String? safeCurrentValue = currentValue;
    if (safeCurrentValue != null && items.isNotEmpty) {
      final valueExists = items.any((item) => item.value == safeCurrentValue);
      if (!valueExists) {
        safeCurrentValue = null;
      }
    }

    return DropdownButtonFormField<String>(
      value: safeCurrentValue,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        helperText: field.readOnly ? 'Read-only' : null,
      ),
      items: items,
      onChanged: field.readOnly
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _dropdownValues[field.name] = value;
                });
              }
            },
      validator: EntityFormLogic.buildValidator(field),
      isExpanded: true,
    );
  }

  @override
  void dispose() {
    _firstFocusNode?.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.entityId != null;

    // Controller
    final controllerKey = widget.entityMeta.entityName;
    final formState = ref.watch(genericFormControllerProvider(controllerKey));
    final controller = ref.read(
      genericFormControllerProvider(controllerKey).notifier,
    );

    // Initial Data Listener
    ref.listen<GenericFormState>(genericFormControllerProvider(controllerKey), (
      prev,
      next,
    ) {
      if (next.initialData != null && !_isDataLoaded) {
        _populateForm(next.initialData!);
      }

      if (next.isSuccess && !next.isLoading) {
        SnackbarUtils.showSuccess(
          '${widget.entityMeta.entityName} saved successfully!',
        );
        context.goNamed(widget.listRouteName);
      } else if (next.error != null && !next.isLoading) {
        ErrorHandler.handle(
          Exception(next.error),
          StackTrace.current,
          context: 'Saving ${widget.entityMeta.entityName}',
          showToUser: true,
        );
      }
    });

    final isInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    if (!isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasPermission = isEditMode
        ? rbacService.canUpdate(widget.rbacModule)
        : rbacService.canCreate(widget.rbacModule);

    if (!hasPermission) {
      return Scaffold(
        appBar: CustomAppBar(
          title: isEditMode
              ? 'Edit ${widget.entityMeta.entityName}'
              : 'Add ${widget.entityMeta.entityName}',
          showBack: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'You do not have permission to ${isEditMode ? 'edit' : 'create'} ${widget.entityMeta.entityNamePluralLower}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditMode
            ? 'Edit ${widget.entityMeta.entityName}'
            : 'Add ${widget.entityMeta.entityName}',
        showBack: true,
      ),
      body: formState.isLoading && !_isDataLoaded && isEditMode
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Generate fields dynamically
                          ..._buildFormFields(formState.dropdownOptions),

                          const SizedBox(height: 8),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE53935),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _onSavePressed(controller),
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (formState.isLoading && _isDataLoaded)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
