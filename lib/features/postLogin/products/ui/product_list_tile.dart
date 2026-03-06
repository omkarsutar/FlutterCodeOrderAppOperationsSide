import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../model/product_model.dart';
import '../../../../core/services/entity_service.dart';
import '../../cart/providers/cart_providers.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../po_items/model/po_item_model.dart';
import '../../../../core/widgets/quantity_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';

class ProductListTile extends ConsumerStatefulWidget {
  final ModelProduct entity;
  final EntityAdapter<ModelProduct> adapter;
  final VoidCallback? onTap;

  const ProductListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
  });

  @override
  ConsumerState<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends ConsumerState<ProductListTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';

    final cartState = ref.watch(cartProvider);
    final cartItemIndex = cartState.items.indexWhere(
      (item) => item.productId == widget.entity.productId,
    );

    // Extract product data using adapter + entity
    final productName =
        widget.adapter
            .getFieldValue(widget.entity, ModelProductFields.productName)
            ?.toString() ??
        '';

    // Normalize image URL (memoize for this build)
    final productImage = () {
      String? img = widget.adapter
          .getFieldValue(widget.entity, ModelProductFields.productImage)
          ?.toString();
      if (img != null && img.isNotEmpty) {
        return Uri.encodeFull(Uri.decodeFull(img));
      }
      return null;
    }();

    final weightValue = widget.adapter.getFieldValue(
      widget.entity,
      ModelProductFields.productWeightValue,
    );
    final weightUnit =
        widget.adapter
            .getFieldValue(widget.entity, ModelProductFields.productWeightUnit)
            ?.toString() ??
        '';
    final retailerRate =
        widget.adapter.getFieldValue(
              widget.entity,
              ModelProductFields.purchaseRateForRetailer,
            )
            as num?;
    final mrp =
        widget.adapter.getFieldValue(widget.entity, ModelProductFields.mrp)
            as num?;
    final packagingType =
        widget.adapter
            .getFieldValue(widget.entity, ModelProductFields.packagingType)
            ?.toString() ??
        '';
    final piecesPerOuter = widget.adapter.getFieldValue(
      widget.entity,
      ModelProductFields.piecesPerOuter,
    );
    final isOuter =
        widget.adapter.getFieldValue(widget.entity, ModelProductFields.isOuter)
            as bool? ??
        false;

    // Format weight
    final weightStr = (weightValue != null && weightUnit.isNotEmpty)
        ? '$weightValue $weightUnit'
        : '';

    // Format pieces per outer
    final outerInfo = isOuter && piecesPerOuter != null
        ? ' • $piecesPerOuter pcs/outer'
        : '';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildProductImage(productImage)),
                // View Icon (Top Left)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      color: theme.colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onTap,
                    ),
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, size: 18),
                        color: theme.colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          final productId = widget.adapter.getFieldValue(
                            widget.entity,
                            ModelProductFields.productId,
                          );
                          if (productId != null) {
                            const baseUrl =
                                AppConstants.webAppHashUrlRetailerApp;
                            final deepLink = '$baseUrl/products/$productId';

                            await Clipboard.setData(
                              ClipboardData(text: deepLink),
                            );

                            if (context.mounted) {
                              SnackbarUtils.showSuccess(
                                'Product link copied to clipboard!',
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$weightStr • ${packagingType.toUpperCase()}$outerInfo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (mrp != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.watch(l10nProvider)['mrp'] ?? 'MRP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${mrp.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    if (cartItemIndex == -1)
                      _buildAddButton(context, ref, theme),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: cartItemIndex != -1
                      ? Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildQtySelector(
                              context,
                              ref,
                              theme,
                              cartState.items[cartItemIndex],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    final cartNotifier = ref.read(cartProvider.notifier);
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {
          final newItem = ModelPoItem(
            productId: widget.entity.productId,
            itemName: widget.entity.productName,
            itemQty: 1.0,
            itemSellRate: widget.entity.purchaseRateForRetailer,
            itemUnitMrp: widget.entity.mrp,
            itemPrice: widget.entity.purchaseRateForRetailer,
            profitToShop:
                (widget.entity.mrp) - (widget.entity.purchaseRateForRetailer),
          );
          cartNotifier.addItem(newItem);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          ref.watch(l10nProvider)['add_to_cart'] ?? 'ADD to Cart',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildQtySelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ModelPoItem cartItem,
  ) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final currentQty = cartItem.itemQty ?? 0.0;

    return QuantitySelector(
      quantity: currentQty,
      isDecimal: widget.entity.qtyInDecimal,
      onQuantityChanged: (newQty) {
        if (newQty != currentQty) {
          cartNotifier.updateQuantity(cartItem.poItemId!, newQty - currentQty);
        }
      },
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity, // Ensure it fills the Expanded parent stably
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              key: ValueKey(imageUrl), // Stable key for the image
              fit: BoxFit.cover,
              // Use fadeIn to make it look premium
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) {
                return const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                );
              },
            )
          : const Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                color: Colors.grey,
                size: 32,
              ),
            ),
    );
  }
}
