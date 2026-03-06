import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../shared/widgets/shared_widget_barrel.dart';
import '../../../../core/routing/module_route_generator.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/entity_page/entity_page_barrel.dart';
import '../../cart/providers/cart_providers.dart';
import '../../../../router/app_routes.dart';
import '../providers/product_providers.dart';
import '../model/product_model.dart';
import '../../po_items/model/po_item_model.dart';

/// Product-specific View Page
/// Decoupled from EntityViewPageRiverpod for customization
class ProductViewPageRiverpod extends ConsumerWidget {
  final String entityId;

  const ProductViewPageRiverpod({super.key, required this.entityId});

  Future<void> _onDeletePressed(
    BuildContext context,
    WidgetRef ref,
    GenericViewController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.deleteEntity(
        deleteFunction: (ref, id) =>
            ref.read(productFormProvider.notifier).delete(id),
        entityId: entityId,
        ref: ref,
      );
    }
  }

  Widget _buildHighlightItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const Divider(height: 24, thickness: 0.5),
      ],
    );
  }

  Widget _buildProductHighlights(
    BuildContext context,
    List<ProcessedEntityField> fields,
    ModelProduct product,
  ) {
    final theme = Theme.of(context);

    // Get specific fields per user request
    final weightVal = fields
        .firstWhere(
          (f) => f.name == 'product_weight_value',
          orElse: () => fields[0],
        )
        .displayValue;
    final weightUnit = fields
        .firstWhere(
          (f) => f.name == 'product_weight_unit',
          orElse: () => fields[0],
        )
        .displayValue;
    final mrp = fields
        .firstWhere((f) => f.name == 'mrp', orElse: () => fields[0])
        .displayValue;
    final packaging = fields
        .firstWhere((f) => f.name == 'packaging_type', orElse: () => fields[0])
        .displayValue;
    final productType = fields
        .firstWhere((f) => f.name == 'product_type', orElse: () => fields[0])
        .displayValue;

    final displayItems = [
      {'label': 'Type', 'value': productType},
      {'label': 'Weight', 'value': '$weightVal $weightUnit'},
      {'label': 'MRP', 'value': mrp},
      {'label': 'Packaging Type', 'value': packaging},
    ];

    // Add Outer Qty if applicable
    if (product.isOuter && product.piecesPerOuter != null) {
      displayItems.add({
        'label': 'Outer Qty',
        'value': '${product.piecesPerOuter} pcs/outer',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product highlights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2, // Increased height to prevent overflow
            crossAxisSpacing: 16,
            mainAxisSpacing: 0,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return _buildHighlightItem(context, item['label']!, item['value']!);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoHeader(
    BuildContext context,
    ThemeData theme,
    String photoUrl,
    String title,
  ) {
    return InkWell(
      onTap: () => _showFullScreenImage(context, photoUrl, title),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(color: Colors.white),
        child: Image.network(
          photoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ProductViewPage: Error loading image: $photoUrl');
            debugPrint('Error: $error');
            return Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(76),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    String photoUrl,
    String title,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();

    showDialog(
      context: context,
      builder: (context) {
        final transformationController = TransformationController();

        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (transformationController.value !=
                          Matrix4.identity()) {
                        transformationController.value = Matrix4.identity();
                      } else {
                        transformationController.value = Matrix4.identity()
                          ..scale(2.5);
                      }
                    },
                    child: InteractiveViewer(
                      transformationController: transformationController,
                      minScale: 0.5,
                      maxScale: 10.0,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(127),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(entityId));
    final productAdapter = ref.watch(productAdapterProvider);
    final isInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final rbacModule = 'product';
    final canUpdate = isInitialized && rbacService.canUpdate(rbacModule);
    final canDelete = isInitialized && rbacService.canDelete(rbacModule);

    const controllerKey = 'Product_view';
    final viewState = ref.watch(genericViewControllerProvider(controllerKey));
    final controller = ref.read(
      genericViewControllerProvider(controllerKey).notifier,
    );

    ref.listen<GenericViewState>(genericViewControllerProvider(controllerKey), (
      previous,
      next,
    ) {
      if (next.isDeleted && !next.isLoading) {
        SnackbarUtils.showSuccess('Product deleted successfully!');
        context.pop();
      } else if (next.error != null && !next.isLoading) {
        SnackbarUtils.showError('Failed to delete: ${next.error}');
      }
    });

    final config = ModuleRouteRegistry.getConfig(rbacModule);
    final fieldConfigs = config?.fields ?? [];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Product Details',
        showBack: context.canPop(),
        actions: [
          if (canUpdate)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.pushNamed(
                  'editProduct',
                  pathParameters: {'id': entityId},
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: viewState.isLoading
                  ? null
                  : () => _onDeletePressed(context, ref, controller),
            ),
        ],
      ),
      drawer: context.canPop() ? null : const CustomDrawer(),
      bottomNavigationBar: productAsync.when(
        data: (product) {
          if (product == null) return null;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                final cartNotifier = ref.read(cartProvider.notifier);

                // Create a PO item from the product
                final newItem = ModelPoItem(
                  productId: product.productId,
                  itemName: product.productName,
                  itemQty: 1.0, // Default quantity
                  itemSellRate: product.purchaseRateForRetailer,
                  itemUnitMrp: product.mrp,
                  itemPrice: product.purchaseRateForRetailer,
                  profitToShop: product.mrp - product.purchaseRateForRetailer,
                );

                // Add to cart - this will set lastModifiedItemId and trigger highlight
                cartNotifier.addItem(newItem);

                context.goNamed(AppRoute.cartName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                minimumSize: const Size(double.infinity, 56), // Full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add to cart',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        },
        loading: () => null,
        error: (err, stack) => null,
      ),
      body: Stack(
        children: [
          productAsync.when(
            data: (product) {
              if (product == null) {
                return const Center(child: Text('Product not found'));
              }

              final processedFields = fieldConfigs.map((field) {
                final fieldName = field.name;
                dynamic value;

                if (fieldName.endsWith('_id')) {
                  value =
                      productAdapter.getLabelValue(product, fieldName) ??
                      productAdapter.getFieldValue(product, fieldName);
                } else {
                  value = productAdapter.getFieldValue(product, fieldName);
                }

                return EntityViewLogic.processField(
                  field: field,
                  value: value,
                  adapter: productAdapter,
                  entity: product,
                );
              }).toList();

              String? headerPhotoUrl = product.productImage;
              if (headerPhotoUrl != null && headerPhotoUrl.isNotEmpty) {
                headerPhotoUrl = Uri.encodeFull(Uri.decodeFull(headerPhotoUrl));
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (headerPhotoUrl != null && headerPhotoUrl.isNotEmpty)
                      _buildPhotoHeader(
                        context,
                        theme,
                        headerPhotoUrl,
                        product.productName,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            product.productName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                              fontSize:
                                  24, // Explicit size to ensure it's prominent
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Highlights Grid
                          _buildProductHighlights(
                            context,
                            processedFields,
                            product,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(err.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          if (viewState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
