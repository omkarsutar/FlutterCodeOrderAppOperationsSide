import 'package:flutter/material.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/date_utils.dart';
import 'package:go_router/go_router.dart';
import '../model/po_collection_model.dart';

class PoCollectionListTile extends StatelessWidget {
  final ModelPoCollection entity;

  const PoCollectionListTile({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.pushNamed(
            'purchase_order_collection',
            pathParameters: {'poId': entity.poId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entity.shopIdLabel ?? 'Unknown Shop',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.route, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            entity.routeIdLabel ?? 'No Route',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatTimestamp(entity.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (entity.isCash)
                    _buildModeChip(
                      'Cash',
                      Icons.money,
                      Colors.orange,
                      amount: entity.collectedAmount,
                    ),
                  if (entity.isOnline)
                    _buildModeChip(
                      'Online',
                      Icons.payment,
                      Colors.blue,
                      amount: entity.collectedAmount,
                    ),
                  if (entity.isCheque)
                    _buildModeChip(
                      'Cheque',
                      Icons.account_balance_wallet,
                      Colors.purple,
                      amount: entity.collectedAmount,
                    ),
                  if (entity.isSign)
                    _buildModeChip(
                      'Credit/Sign',
                      Icons.assignment_ind,
                      Colors.red,
                      amount: entity.signAmount,
                    ),
                ],
              ),
              if (entity.comments != null && entity.comments!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  entity.comments!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(
    String label,
    IconData icon,
    Color color, {
    double? amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (amount != null && amount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '₹${amount.ceil()}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
