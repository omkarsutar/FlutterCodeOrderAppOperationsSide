import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../model/product_model.dart';
import '../../../../core/services/entity_service.dart';

class ProductListTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';

    // Extract product data using adapter + entity
    final productName =
        adapter
            .getFieldValue(entity, ModelProductFields.productName)
            ?.toString() ??
        '';

    // Normalize image URL
    String? productImage = adapter
        .getFieldValue(entity, ModelProductFields.productImage)
        ?.toString();
    if (productImage != null && productImage.isNotEmpty) {
      productImage = Uri.encodeFull(Uri.decodeFull(productImage));
    }

    final weightValue = adapter.getFieldValue(
      entity,
      ModelProductFields.productWeightValue,
    );
    final weightUnit =
        adapter
            .getFieldValue(entity, ModelProductFields.productWeightUnit)
            ?.toString() ??
        '';
    final retailerRate =
        adapter.getFieldValue(
              entity,
              ModelProductFields.purchaseRateForRetailer,
            )
            as num?;
    final mrp = adapter.getFieldValue(entity, ModelProductFields.mrp) as num?;
    final packagingType =
        adapter
            .getFieldValue(entity, ModelProductFields.packagingType)
            ?.toString() ??
        '';
    final piecesPerOuter = adapter.getFieldValue(
      entity,
      ModelProductFields.piecesPerOuter,
    );
    final isOuter =
        adapter.getFieldValue(entity, ModelProductFields.isOuter) as bool? ??
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
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildProductImage(productImage)),
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
                            final productId = adapter.getFieldValue(
                              entity,
                              ModelProductFields.productId,
                            );
                            if (productId != null) {
                              const baseUrl =
                                  'https://omkarsutar.github.io/OrderAppV01/#';
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
                              'MRP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              '₹${mrp.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                // decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      if (retailerRate != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rate',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${retailerRate.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('ProductListTile: Error loading image: $imageUrl');
                debugPrint('Error: $error');
                return const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                );
              },
            )
          : const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.grey,
              size: 32,
            ),
    );
  }
}
