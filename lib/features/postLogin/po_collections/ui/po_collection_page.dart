import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../purchase_orders/purchase_order_barrel.dart';
import '../providers/po_collection_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class PurchaseOrderCollectionPage extends ConsumerWidget {
  final String poId;

  const PurchaseOrderCollectionPage({super.key, required this.poId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poAsync = ref.watch(purchaseOrderByIdProvider(poId));
    final formState = ref.watch(poCollectionFormProvider);
    final formNotifier = ref.read(poCollectionFormProvider.notifier);
    final theme = Theme.of(context);

    // Load existing collection if any
    ref.listen(poCollectionByPoIdProvider(poId), (previous, next) {
      // Ensure poId is set in the notifier
      formNotifier.updateField('po_id', poId);

      if (next.hasValue && next.value != null) {
        formNotifier.resetWith(next.value!);
      }
    });

    // Also ensure poId is set even if no existing collection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      formNotifier.updateField('po_id', poId);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Collect Payment')),
      body: poAsync.when(
        data: (po) {
          if (po == null) return const Center(child: Text('PO not found'));

          final shopName =
              po.resolvedLabels['po_shop_id_label'] ?? 'Unknown Shop';
          final billAmount = po.poTotalAmount ?? 0.0;
          final currencyFormat = NumberFormat.currency(
            symbol: '₹',
            decimalDigits: 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shop Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shopName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.route,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              po.resolvedLabels['po_route_id_label'] ??
                                  'No Route',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.update,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'PO Updated: ${formatTimestamp(po.updatedAt)}',
                                      style: theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bill: ${currencyFormat.format(billAmount)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Collected Amount
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Actually Collected Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  initialValue: formState.collectedAmount > 0
                      ? formState.collectedAmount.ceil().toString()
                      : '',
                  onChanged: (value) => formNotifier.updateCollectedAmount(
                    double.tryParse(value) ?? 0.0,
                  ),
                ),
                const SizedBox(height: 20),

                // Collection Mode
                Text('Collection Mode', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilterChip(
                      label: const Text('Cash'),
                      selected: formState.isCash,
                      onSelected: (v) => formNotifier.toggleCash(v),
                    ),
                    FilterChip(
                      label: const Text('Online'),
                      selected: formState.isOnline,
                      onSelected: (v) => formNotifier.toggleOnline(v),
                    ),
                    FilterChip(
                      label: const Text('Cheque'),
                      selected: formState.isCheque,
                      onSelected: (v) => formNotifier.toggleCheque(v),
                    ),
                  ],
                ),

                // Cheque Number field (Conditional)
                if (formState.isCheque) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: formState.chequeNo,
                    onChanged: (value) => formNotifier.updateChequeNo(value),
                  ),
                ],

                const Divider(height: 40),

                // Sign (Credit) Checkbox
                CheckboxListTile(
                  title: const Text('Sign (Credit given to shop)'),
                  value: formState.isSign,
                  onChanged: (v) => formNotifier.toggleSign(v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // Sign Amount field (Conditional)
                if (formState.isSign) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Actual Sign Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    initialValue:
                        formState.signAmount != null &&
                            formState.signAmount! > 0
                        ? formState.signAmount!.ceil().toString()
                        : '',
                    onChanged: (value) => formNotifier.updateSignAmount(
                      double.tryParse(value) ?? 0.0,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Comments
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  initialValue: formState.comments,
                  onChanged: (value) => formNotifier.updateComments(value),
                ),

                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: formState.isLoading
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Save'),
                              content: const Text(
                                'Are you sure you want to save this collection details?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final success = await formNotifier.save();
                          if (success) {
                            SnackbarUtils.showSuccess(
                              'Collection saved successfully',
                            );
                            if (context.mounted) context.pop();
                          } else {
                            SnackbarUtils.showError(
                              formState.error ?? 'Failed to save collection',
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: formState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Collection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
