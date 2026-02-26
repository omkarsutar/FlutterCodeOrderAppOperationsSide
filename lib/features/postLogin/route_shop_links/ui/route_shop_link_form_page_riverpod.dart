import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/field_config.dart';
import '../../../../../core/models/entity_meta.dart';
import '../../../../../core/services/core_services_barrel.dart';
import '../../../../../core/utils/core_utils_barrel.dart';
import '../../../../../core/validators/form_validators.dart';
import '../../../../../shared/widgets/shared_widget_barrel.dart';
import '../../../../../core/providers/core_providers.dart';
import '../route_shop_link_barrel.dart';

/// Route Shop Links specific Form Page
/// Customized for route_shop_links module following Single Responsibility Principle
class RouteShopLinkFormPageRiverpod<T> extends ConsumerStatefulWidget {
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

  const RouteShopLinkFormPageRiverpod({
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
  ConsumerState<RouteShopLinkFormPageRiverpod<T>> createState() =>
      _RouteShopLinkFormPageRiverpodState<T>();
}

class _RouteShopLinkFormPageRiverpodState<T>
    extends ConsumerState<RouteShopLinkFormPageRiverpod<T>> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _switchValues = {};
  final Map<String, dynamic> _dropdownValues = {}; // Store selected IDs

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
        routeShopLinksFormControllerProvider(
          widget.entityMeta.entityName,
        ).notifier,
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
      } else if (field.type == FieldType.dropdown) {
        if (value != null) {
          setState(() => _dropdownValues[field.name] = value.toString());
        }
      } else if (value != null) {
        _controllers[field.name]?.text = value.toString();
      }
    }

    setState(() => _isDataLoaded = true);
  }

  Future<void> _onSavePressed(RouteShopLinksFormController controller) async {
    if (!_formKey.currentState!.validate()) return;

    // Collect field values
    final fieldValues = <String, dynamic>{};
    for (var field in widget.fieldConfigs) {
      if (field.type == FieldType.switchField) {
        fieldValues[field.name] = _switchValues[field.name] ?? false;
      } else if (field.type == FieldType.dropdown) {
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
      validator: _buildValidator(field),
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
      validator: _buildValidator(field),
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
        validator: _buildValidator(field),
      );
    }

    // Dynamic Options from Controller State
    final options = dropdownOptions[field.name] ?? [];
    final currentValue = _dropdownValues[field.name];

    // If we have a current value but no options yet, show a disabled field with current value
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

    // If we have options but no current value, set the first one as default
    if (currentValue == null && items.isNotEmpty) {
      // We can't setState during build easily, but user hasn't interacted yet.
      // We'll just show it selected if we force value = item.first.value,
      // but to persist it we need to update _dropdownValues.
      // Better to leave it null or let user pick.
      // Or, use postFrame callback if strictly needed.
    }

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
      validator: _buildValidator(field),
      isExpanded: true,
    );
  }

  String? Function(String?)? _buildValidator(FieldConfig field) {
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
    final formState = ref.watch(
      routeShopLinksFormControllerProvider(controllerKey),
    );
    final controller = ref.read(
      routeShopLinksFormControllerProvider(controllerKey).notifier,
    );

    // Initial Data Listener
    ref.listen<RouteShopLinksFormState>(
      routeShopLinksFormControllerProvider(controllerKey),
      (prev, next) {
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
      },
    );

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
                          // Route Shop Links specific header
                          if (widget.entityMeta.entityName.contains(
                            'Route Shop Link',
                          ))
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Route Shop Link Configuration',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),

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
