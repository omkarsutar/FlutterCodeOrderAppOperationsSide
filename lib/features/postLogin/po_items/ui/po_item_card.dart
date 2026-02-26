import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/product_barrel.dart';
import '../model/po_item_model.dart';
import '../providers/po_item_list_controller.dart';

class PoItemCard extends ConsumerStatefulWidget {
  final ModelPoItem entity;
  final List<ModelProduct> products;
  final String poId;

  const PoItemCard({
    super.key,
    required this.entity,
    required this.products,
    required this.poId,
  });

  @override
  ConsumerState<PoItemCard> createState() => _PoItemCardState();
}

class _PoItemCardState extends ConsumerState<PoItemCard> {
  late TextEditingController _qtyController;
  late double _currentQty;
  Timer? _debounceTimer;
  bool _isExpanded = false;
  bool _isTransitionHighlighted = false;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _currentQty = widget.entity.itemQty ?? 0.0;
    _qtyController = TextEditingController(text: _formatQty(_currentQty));
  }

  @override
  void didUpdateWidget(covariant PoItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.itemQty != widget.entity.itemQty) {
      _currentQty = widget.entity.itemQty ?? 0.0;
      final newText = _formatQty(_currentQty);
      if (_qtyController.text != newText) {
        _qtyController.text = newText;
      }
    }
  }

  void _triggerHighlight() {
    if (!mounted) return;
    setState(() => _isTransitionHighlighted = true);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isTransitionHighlighted = false);
      }
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _debounceTimer?.cancel();
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

  double get _mrp => _product?.mrp ?? 0.0;
  double get _sellRate => _product?.purchaseRateForRetailer ?? 0.0;
  double get _price => _currentQty * _sellRate;

  String _formatQty(double val) {
    String text = val.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  String _formatCurrency(num value) => '₹${value.toStringAsFixed(2)}';

  void _updateQty(double val) {
    setState(() {
      _currentQty = val;
      _qtyController.text = _formatQty(val);
    });
    _triggerUpdate(val);
  }

  void _triggerUpdate(double val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final updated = widget.entity.copyWith(
        itemQty: val,
        itemPrice: val * _sellRate,
      );
      ref
          .read(poItemListControllerProvider(widget.poId).notifier)
          .updateItem(updated, widget.poId);
    });
  }

  Future<void> _selectProduct() async {
    final result = await context.pushNamed(
      ProductsRoutesJson.listRouteName,
      queryParameters: {'selection': 'true'},
    );

    if (result is ModelProduct) {
      final updated = widget.entity.copyWith(
        productId: result.productId,
        itemSellRate: result.purchaseRateForRetailer,
        itemUnitMrp: result.mrp,
        itemPrice: _currentQty * result.purchaseRateForRetailer,
      );
      ref
          .read(poItemListControllerProvider(widget.poId).notifier)
          .updateItem(updated, widget.poId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastModifiedId = ref.watch(
      poItemListControllerProvider(
        widget.poId,
      ).select((asyncState) => asyncState.value?.lastModifiedItemId),
    );

    // Trigger highlight if this item was the last one modified
    if (lastModifiedId == widget.entity.poItemId && !_isTransitionHighlighted) {
      // Use a microtask to avoid calling setState during build
      Future.microtask(() => _triggerHighlight());
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isTransitionHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _isTransitionHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 8.0, 8.0, 8.0),
          child: Column(
            children: [
              // Row 1: Product Selection + Qty Controls + Expand Button
              Row(
                children: [
                  // Expand/Collapse Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 2,
                    ), // reduce horizontal padding
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ), // tighter box
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ), // shrink further
                  ),

                  // Product Selection
                  Expanded(
                    child: InkWell(
                      onTap: _selectProduct,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Product',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _product?.productName ?? 'Select Product',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Qty Controls (Fixed Width)
                  SizedBox(
                    width: 140, // Slightly wider for comfort
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_currentQty > 0) {
                              final newValue = _currentQty - 1.0;
                              _updateQty(newValue < 0 ? 0 : newValue);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: _product?.qtyInDecimal ?? false,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: UnderlineInputBorder(),
                            ),
                            inputFormatters: [
                              if (_product?.qtyInDecimal ?? false)
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                                )
                              else
                                FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              final d = double.tryParse(val) ?? 0;
                              setState(() => _currentQty = d);
                              _triggerUpdate(d);
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateQty(_currentQty + 1.0),
                          icon: const Icon(Icons.add_circle_outline),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Row 2: Collapsible Details
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoText('MRP', _formatCurrency(_mrp)),
                    _buildInfoText('Rate', _formatCurrency(_sellRate)),
                    _buildInfoText(
                      'Price',
                      _formatCurrency(_price),
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Delete Button (Optional but good UX)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      if (widget.entity.poItemId != null) {
                        await ref
                            .read(
                              poItemListControllerProvider(
                                widget.poId,
                              ).notifier,
                            )
                            .deleteItem(widget.entity.poItemId!, widget.poId);
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    label: const Text(
                      'Remove Item',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
