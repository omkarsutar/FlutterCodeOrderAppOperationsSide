import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import '../providers/cart_providers.dart';
import '../providers/cart_view_logic.dart';
import '../providers/cart_controller.dart';
import '../../products/product_barrel.dart';
import 'cart_item_card.dart';
import 'cart_add_section.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _profitHighlightController;
  late Animation<double> _profitScaleAnimation;
  late Animation<Color?> _profitColorAnimation;

  @override
  void initState() {
    super.initState();
    _profitHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _profitScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.easeInOut,
          ),
        );

    _profitColorAnimation =
        ColorTween(
          begin: Colors.green.withValues(alpha: 0.2),
          end: Colors.white,
        ).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.linear,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider).initPendingOrder(context);
    });
  }

  @override
  void dispose() {
    _profitHighlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final viewData = ref.watch(cartViewLogicProvider);
    final isEditing = ref.watch(isEditingCartItemProvider);
    final products = ref.watch(productsStreamProvider).value ?? [];

    // Trigger animation when profit or item count changes
    ref.listen(
      cartViewLogicProvider.select((d) => (d.totalProfit, d.itemCount)),
      (previous, next) {
        if (previous != next && next.$1 != '0.00') {
          _profitHighlightController.forward(from: 0.0);
        }
      },
    );

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Cart', showBack: false),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          if (!viewData.isEmpty) _buildCartSummary(context, viewData),
          Expanded(
            child: viewData.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    itemCount: viewData.items.length,
                    itemBuilder: (context, index) {
                      final processedItem = viewData.items[index];
                      return CartItemCard(
                        key: ValueKey(processedItem.item.poItemId),
                        entity: processedItem.item,
                        products: products,
                      );
                    },
                  ),
          ),
          if (!isEditing && !cartState.isNewItemAdded)
            CartAddSection(products: products),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, ProcessedCartData viewData) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      'Items',
                      viewData.itemCount.toString(),
                    ),
                    AnimatedBuilder(
                      animation: _profitHighlightController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _profitHighlightController.value > 0
                                ? _profitColorAnimation.value
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ScaleTransition(
                            scale: _profitScaleAnimation,
                            child: _buildSummaryItem(
                              context,
                              'Shop Profit on MRP',
                              '₹${viewData.totalProfit}',
                              color: Colors.green,
                              valueSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSummaryItem(
                      context,
                      'Total Amount',
                      '₹${viewData.totalAmount}',
                      isBold: true,
                      crossAxisAlignment: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const Divider(height: 24),
            _buildSummaryTable(context, viewData),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(cartControllerProvider).clearCart(context),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    'Empty Cart',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(cartControllerProvider)
                      .handleOrderAction(context, viewData),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Place Order',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTable(BuildContext context, ProcessedCartData viewData) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 11);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Item Name',
                style: textStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Qty',
                textAlign: TextAlign.right,
                style: textStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Rate',
                textAlign: TextAlign.right,
                style: textStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Amt',
                textAlign: TextAlign.right,
                style: textStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...viewData.items.map((processedItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    processedItem.productName,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    processedItem.formattedQty,
                    textAlign: TextAlign.right,
                    style: textStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    processedItem.formattedRate,
                    textAlign: TextAlign.right,
                    style: textStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    processedItem.formattedAmount,
                    textAlign: TextAlign.right,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double? valueSize,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? theme.colorScheme.onSurface,
      fontSize: valueSize ?? 14,
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}
