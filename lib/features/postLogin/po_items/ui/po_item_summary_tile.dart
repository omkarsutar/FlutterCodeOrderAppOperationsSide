import 'package:flutter/material.dart';

import '../model/po_item_model.dart';

class PoItemSummaryTile extends StatelessWidget {
  final ModelPoItem item;

  const PoItemSummaryTile({super.key, required this.item});

  String get _qtyText {
    if (item.itemQty == null) return '-';
    final qty = double.tryParse(item.itemQty.toString()) ?? 0.0;
    final rounded = qty.round();
    if (qty == rounded) {
      return rounded.toString();
    } else {
      return qty.toStringAsFixed(1);
    }
  }

  String get _rateText => item.itemSellRate != null
      ? '${item.itemSellRate!.toStringAsFixed(2)}'
      : '-';

  String get _amountText =>
      item.itemPrice != null ? '${item.itemPrice!.toStringAsFixed(2)}' : '-';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.itemName ?? 'Unnamed item',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              _qtyText,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              _rateText,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              _amountText,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
