import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../po_items/model/po_item_model.dart';
import '../../products/product_barrel.dart';
import '../providers/cart_providers.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../../../core/widgets/quantity_selector.dart';

class CartItemCard extends ConsumerStatefulWidget {
  final ModelPoItem entity;
  final List<ModelProduct> products;
  final bool isReadOnly;

  const CartItemCard({
    super.key,
    required this.entity,
    required this.products,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<CartItemCard> {
  late double _currentQty;
  late FocusNode _focusNode;
  bool _isHighlighted = false;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _currentQty = widget.entity.itemQty ?? 0.0;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      ref.read(isEditingCartItemProvider.notifier).state = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(covariant CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.itemQty != widget.entity.itemQty) {
      _currentQty = widget.entity.itemQty ?? 0.0;
    }
  }

  void _triggerHighlight() {
    if (!mounted) return;
    setState(() => _isHighlighted = true);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isHighlighted = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  ModelProduct? get _product {
    try {
      return widget.products.firstWhere(
        (p) => p.productId == widget.entity.productId,
      );
    } catch (_) {
      return null;
    }
  }

  double get _sellRate => widget.entity.itemSellRate ?? 0.0;
  double get _price => _currentQty * _sellRate;

  String _formatCurrency(num value) => '₹${value.toStringAsFixed(2)}';

  double _roundQty(double val) => (val * 10).roundToDouble() / 10;

  void _updateQuantity(double newQty) {
    final rounded = _roundQty(newQty);
    if (rounded != (widget.entity.itemQty ?? 0)) {
      ref
          .read(cartProvider.notifier)
          .updateQuantity(
            widget.entity.poItemId!,
            rounded - (widget.entity.itemQty ?? 0),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastModifiedId = ref.watch(
      cartProvider.select((s) => s.lastModifiedItemId),
    );

    if (lastModifiedId == widget.entity.poItemId && !_isHighlighted) {
      Future.microtask(() => _triggerHighlight());
    }

    final product = _product;
    String? productImage = product?.productImage;
    if (productImage != null && productImage.isNotEmpty) {
      productImage = Uri.encodeFull(Uri.decodeFull(productImage));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: _isHighlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  child: (productImage != null && productImage.isNotEmpty)
                      ? Image.network(
                          productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final currentLanguage = ref.watch(
                                languageProvider,
                              );
                              final useHindi =
                                  currentLanguage == AppLanguage.hindi ||
                                  currentLanguage == AppLanguage.marathi;

                              String displayName =
                                  widget.entity.itemName ?? 'Unnamed Item';

                              if (useHindi && product != null) {
                                final hindiName = product.productNameHindi;
                                if (hindiName != null && hindiName.isNotEmpty) {
                                  displayName = hindiName;
                                }
                              }

                              return Text(
                                displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (!widget.isReadOnly)
                          GestureDetector(
                            onTap: () => ref
                                .read(cartProvider.notifier)
                                .removeItem(widget.entity.poItemId!),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.7,
                              ),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate: ${_formatCurrency(_sellRate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _formatCurrency(_price),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        // Qty Selector
                        SizedBox(
                          width: 140,
                          child: QuantitySelector(
                            quantity: _currentQty,
                            onQuantityChanged: _updateQuantity,
                            isDecimal: _product?.qtyInDecimal ?? false,
                            focusNode: _focusNode,
                            height: 36,
                            readOnly: widget.isReadOnly,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
