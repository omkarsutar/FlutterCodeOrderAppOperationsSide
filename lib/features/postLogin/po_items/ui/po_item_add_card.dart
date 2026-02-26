import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:go_router/go_router.dart';
import '../model/po_item_model.dart';
import '../providers/po_item_add_logic.dart';
import '../providers/po_item_list_controller.dart';

class PoItemAddCard extends ConsumerStatefulWidget {
  final List<ModelProduct> products;
  final String poId;

  const PoItemAddCard({super.key, required this.products, required this.poId});

  @override
  ConsumerState<PoItemAddCard> createState() => _PoItemAddCardState();
}

class _PoItemAddCardState extends ConsumerState<PoItemAddCard> {
  final TextEditingController _qtyController = TextEditingController();
  String? _selectedProductId;
  ModelProduct? _selectedProduct;
  double _currentQty = 0.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  ModelProduct? get _product => _selectedProduct;

  double get _mrp => PoItemAddLogic.getProductMrp(_product);
  double get _sellRate => PoItemAddLogic.getProductRate(_product);
  double get _price => PoItemAddLogic.calculatePrice(_currentQty, _sellRate);

  void _updateQty(double val) {
    setState(() {
      _currentQty = val;
      _qtyController.text = PoItemAddLogic.formatQty(val);
    });
  }

  Future<void> _selectProduct() async {
    final result = await context.pushNamed(
      ProductsRoutesJson.listRouteName, // ✅ use ProductsRoutesJson
      queryParameters: {'selection': 'true'},
    );

    if (result is ModelProduct) {
      if (mounted) {
        setState(() {
          _selectedProduct = result;
          _selectedProductId = result.productId;
        });
      }
    }
  }

  Future<void> _handleAdd() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }
    if (_currentQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }

    // Check for duplicate product in this PO
    final existingItems =
        ref.read(poItemListControllerProvider(widget.poId)).value?.items ?? [];
    final isAlreadyPresent = existingItems.any(
      (item) => item.productId == _selectedProductId,
    );

    if (isAlreadyPresent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedProduct!.productName} is already added.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newItem = ModelPoItem(
      poId: widget.poId,
      productId: _selectedProductId,
      itemQty: _currentQty,
      itemSellRate: _sellRate,
      itemUnitMrp: _mrp,
      itemPrice: _price,
    );

    final success = await ref
        .read(poItemListControllerProvider(widget.poId).notifier)
        .addItem(newItem, widget.poId);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Reset form
        setState(() {
          _selectedProduct = null;
          _selectedProductId = null;
          _currentQty = 0;
          _qtyController.text = "";
        });
      } else {
        // Error handled by controller/state usually, or we can check state.error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purpleBg = Colors.purple.shade900;
    const contrastColor = Colors.white;
    final accentColor = Colors.purple.shade100;

    return Container(
      decoration: BoxDecoration(
        color: purpleBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 3),
        ),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        children: [
          // Header "New Item"
          Text(
            "New Item",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: contrastColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: contrastColor.withValues(alpha: 0.2),
            thickness: 1.2,
            indent: 80,
            endIndent: 80,
          ),
          const SizedBox(height: 8),

          // Row 1: Product Selection + Qty
          Row(
            children: [
              // Product Selection
              Expanded(
                child: InkWell(
                  onTap: _selectProduct,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Product',
                      labelStyle: TextStyle(color: accentColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    child: Text(
                      _product?.productName ?? 'Select Product',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Qty Controls
              SizedBox(
                width: 140,
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
                      color: accentColor,
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
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: accentColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                          hintText: '0',
                          hintStyle: const TextStyle(color: Colors.grey),
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
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQty(_currentQty + 1.0),
                      icon: const Icon(Icons.add_circle_outline),
                      color: accentColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Info + Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoText(
                'MRP',
                PoItemAddLogic.formatCurrency(_mrp),
                color: accentColor,
              ),
              _buildInfoText(
                'Rate',
                PoItemAddLogic.formatCurrency(_sellRate),
                color: accentColor,
              ),
              _buildInfoText(
                'Price',
                PoItemAddLogic.formatCurrency(_price),
                isBold: true,
                color: contrastColor,
              ),

              // Add Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleAdd,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text("Add Item"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: contrastColor,
                  foregroundColor: purpleBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color?.withValues(alpha: 0.7) ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
