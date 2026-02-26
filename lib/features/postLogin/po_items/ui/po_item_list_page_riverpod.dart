import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/module_config.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import '../providers/po_item_providers.dart';
import '../providers/po_item_list_controller.dart';
import 'po_item_add_card.dart';
import 'po_item_card.dart';

class PoItemListPageRiverpod extends ConsumerStatefulWidget {
  final String poId;
  final String entityLabel;
  final String viewRouteName;
  final String newRouteName;
  final SortingConfig? initialSorting;

  const PoItemListPageRiverpod({
    super.key,
    required this.poId,
    required this.entityLabel,
    required this.viewRouteName,
    required this.newRouteName,
    this.initialSorting,
  });

  @override
  ConsumerState<PoItemListPageRiverpod> createState() =>
      _PoItemListPageRiverpodState();
}

class _PoItemListPageRiverpodState
    extends ConsumerState<PoItemListPageRiverpod> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(poItemServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch items for this PO
    final asyncState = ref.watch(poItemListControllerProvider(widget.poId));

    // Watch the purchase order itself by ID
    final poAsync = ref.watch(purchaseOrderStreamByIdProvider(widget.poId));

    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.entityLabel}s for PO',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Purchase Order card at the top (Header)
                SliverToBoxAdapter(
                  child: poAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error loading order: $err'),
                    data: (po) {
                      if (po == null) return const Text('Order not found');
                      return PurchaseOrderListTile(
                        entity: po,
                        adapter: ref.read(purchaseOrderAdapterProvider),
                        onTap: null,
                        poItemTile: true,
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: Divider()),

                // Items list
                asyncState.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.refresh(
                                poItemListControllerProvider(widget.poId),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (state) {
                    if (state.items.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text('No items found. Add one below.'),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = state.items[index];
                          return PoItemCard(
                            key: ValueKey(item.poItemId),
                            entity: item,
                            products: state.products,
                            poId: widget.poId,
                          );
                        }, childCount: state.items.length),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Add Card
          if (asyncState.value?.isNewItemAdded != true)
            PoItemAddCard(
              products: asyncState.value?.products ?? [],
              poId: widget.poId,
            ),
        ],
      ),
    );
  }
}
