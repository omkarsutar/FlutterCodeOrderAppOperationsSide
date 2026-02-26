import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:go_router/go_router.dart';
import '../../po_items/model/po_item_model.dart';
import '../../products/product_routes_json.dart';
import '../providers/cart_providers.dart';

class CartAddSection extends ConsumerStatefulWidget {
  final List<ModelProduct> products;

  const CartAddSection({super.key, required this.products});

  @override
  ConsumerState<CartAddSection> createState() => _CartAddSectionState();
}

class _CartAddSectionState extends ConsumerState<CartAddSection> {
  final TextEditingController _qtyController = TextEditingController();
  ModelProduct? _selectedProduct;
  double _currentQty = 0.0;

  @override
  void initState() {
    super.initState();
    // Check for pre-selected product (e.g. from guest landing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final preSelected = ref.read(selectedProductForAdditionProvider);
      if (preSelected != null) {
        setState(() {
          _selectedProduct = preSelected;
        });
        // Clear it so it doesn't re-select if coming back to cart later
        ref.read(selectedProductForAdditionProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  double get _mrp => _selectedProduct?.mrp ?? 0.0;
  double get _sellRate => _selectedProduct?.purchaseRateForRetailer ?? 0.0;
  double get _price => _currentQty * _sellRate;

  String _formatQty(double val) {
    if (val == 0) return "";
    String text = val.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  String _formatCurrency(num value) => '₹${value.toStringAsFixed(2)}';

  double _roundQty(double val) => (val * 10).roundToDouble() / 10;

  void _updateQty(double val) {
    final rounded = _roundQty(val);
    setState(() {
      _currentQty = rounded;
      _qtyController.text = _formatQty(rounded);
    });
  }

  Future<void> _selectProduct() async {
    final result = await context.pushNamed(
      ProductsRoutesJson.listRouteName,
      queryParameters: {'selection': 'true'},
    );

    if (result is ModelProduct) {
      if (mounted) {
        setState(() {
          _selectedProduct = result;
        });
      }
    }
  }

  void _handleAdd() {
    if (_selectedProduct == null) {
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

    // Check for duplicate product in cart
    final cartItems = ref.read(cartProvider).items;
    final isAlreadyPresent = cartItems.any(
      (item) => item.productId == _selectedProduct!.productId,
    );

    if (isAlreadyPresent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedProduct!.productName} is already in cart'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final newItem = ModelPoItem(
      productId: _selectedProduct!.productId,
      itemName: _selectedProduct!.productName,
      itemQty: _currentQty,
      itemSellRate: _sellRate,
      itemUnitMrp: _mrp,
      itemPrice: _price,
      profitToShop: (_mrp - _sellRate) * _currentQty,
    );

    ref.read(cartProvider.notifier).addItem(newItem);

    setState(() {
      _selectedProduct = null;
      _currentQty = 0;
      _qtyController.text = "";
    });
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Add to Cart",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: contrastColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                      _selectedProduct?.productName ?? 'Select Product',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                          decimal: _selectedProduct?.qtyInDecimal ?? false,
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
                          ),
                          hintText: '0',
                        ),
                        inputFormatters: [
                          if (_selectedProduct?.qtyInDecimal ?? false)
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                            )
                          else
                            FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) => setState(
                          () => _currentQty = _roundQty(
                            double.tryParse(val) ?? 0,
                          ),
                        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoText('MRP', _formatCurrency(_mrp), color: accentColor),
              _buildInfoText(
                'Rate',
                _formatCurrency(_sellRate),
                color: accentColor,
              ),
              _buildInfoText(
                'Price',
                _formatCurrency(_price),
                isBold: true,
                color: contrastColor,
              ),
              ElevatedButton.icon(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Add to Cart"),
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
