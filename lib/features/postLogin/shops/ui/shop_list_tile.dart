import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../shop_barrel.dart';

class ShopListTile<T> extends ConsumerWidget {
  final T entity;
  final EntityAdapter<T> adapter;
  final String idField;
  final String entityLabel;
  final String entityLabelLower;
  final String viewRouteName;
  final String rbacModule;
  final VoidCallback? onTap;

  const ShopListTile({
    super.key,
    required this.entity,
    required this.adapter,
    required this.idField,
    required this.entityLabel,
    required this.entityLabelLower,
    required this.viewRouteName,
    required this.rbacModule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rbacService = ref.watch(rbacServiceProvider);
    final canCopyLink = rbacService.canCreate(rbacModule);
    final shopName =
        adapter.getFieldValue(entity, ModelShopFields.shopName) ??
        'Unnamed Shop';
    final visitOrder = adapter.getFieldValue(
      entity,
      ModelShopFields.visitOrder,
    );
    final displayName = visitOrder != null
        ? '$visitOrder. $shopName'
        : shopName.toString();

    final shopNote =
        adapter.getFieldValue(entity, ModelShopFields.shopNote)?.toString() ??
        '';
    final hiddenNote =
        adapter.getFieldValue(entity, ModelShopFields.hiddenNote)?.toString() ??
        '';
    final photoUrl =
        adapter.getFieldValue(entity, ModelShopFields.shopPhotoUrl) as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // onTap: () => _handleCreatePurchaseOrder(context),
        // onTap: onTap ?? () => _handleCreatePurchaseOrder(context),
        onTap: onTap ?? () => onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.store,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 40,
                            );
                          },
                        )
                      : Icon(
                          Icons.store,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Right Side: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Name
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Shop Note under name
                    if (shopNote.isNotEmpty)
                      Text(
                        shopNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 4),

                    // Hidden Note under shop note
                    if (hiddenNote.isNotEmpty)
                      Text(
                        hiddenNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 4),

                    // Mobiles + Person name
                    Builder(
                      builder: (_) {
                        final mobile1 = adapter.getFieldValue(
                          entity,
                          ModelShopFields.shopMobile1,
                        );
                        final mobile2 = adapter.getFieldValue(
                          entity,
                          ModelShopFields.shopMobile2,
                        );
                        final personName = adapter.getFieldValue(
                          entity,
                          ModelShopFields.shopPersonName,
                        );

                        final contactLine = [
                          if (mobile1 != null && mobile1.toString().isNotEmpty)
                            mobile1.toString(),
                          if (mobile2 != null && mobile2.toString().isNotEmpty)
                            mobile2.toString(),
                        ].join(", ");

                        final displayLine =
                            personName != null &&
                                personName.toString().isNotEmpty
                            ? "$contactLine (${personName.toString()})"
                            : contactLine;

                        return Text(
                          displayLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                    ),

                    // Row 3: Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canCopyLink &&
                            (_isValidMobile(
                                  adapter.getFieldValue(
                                    entity,
                                    ModelShopFields.shopMobile1,
                                  ),
                                ) ||
                                _isValidMobile(
                                  adapter.getFieldValue(
                                    entity,
                                    ModelShopFields.shopMobile2,
                                  ),
                                )))
                          InkWell(
                            onTap: () => _copyUtmLink(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.link,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => _openMap(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.location_on,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.pushNamed(
                            viewRouteName,
                            pathParameters: {
                              'id': adapter.getId(entity, idField).toString(),
                            },
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.visibility,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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

  Future<void> _openMap(BuildContext context) async {
    final lat = adapter.getFieldValue(entity, ModelShopFields.shopLat);
    final long = adapter.getFieldValue(entity, ModelShopFields.shopLong);
    if (lat == null || long == null) {
      SnackbarUtils.showError('Shop location not available');
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$long';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyUtmLink(BuildContext context) async {
    // Get shop mobile numbers
    final mobile1 = adapter
        .getFieldValue(entity, ModelShopFields.shopMobile1)
        ?.toString();
    final mobile2 = adapter
        .getFieldValue(entity, ModelShopFields.shopMobile2)
        ?.toString();

    // Select first valid 10-digit mobile number
    String? selectedMobile;
    if (_isValidMobile(mobile1)) {
      selectedMobile = mobile1;
    } else if (_isValidMobile(mobile2)) {
      selectedMobile = mobile2;
    }

    if (selectedMobile == null) {
      SnackbarUtils.showError(
        'Valid 10-digit shop mobile number not available',
      );
      return;
    }

    final mobileNumber = selectedMobile;

    // Translate mobile number digits to characters
    final translationMap = {
      '0': 'a',
      '1': 'b',
      '2': 'c',
      '3': 'd',
      '4': 'e',
      '5': 'f',
      '6': 'g',
      '7': 'h',
      '8': 'i',
      '9': 'j',
    };

    final utmSource = mobileNumber
        .split('')
        .map((digit) {
          return translationMap[digit] ?? digit;
        })
        .join('');

    final utmLink =
        '${AppConstants.webAppUrlRetailerApp}?utm_source=$utmSource';
    // 'https://omkarsutar.github.io/OrderAppV01?utm_source=$utmSource';

    // Copy to clipboard
    // Share to WhatsApp if mobile number is available
    if (_isValidMobile(mobileNumber)) {
      // Validate and format mobile number
      String formattedMobile = mobileNumber;

      if (mobileNumber.length == 10) {
        // Add '91' prefix for 10-digit numbers
        formattedMobile = '91$mobileNumber';
      } else if (mobileNumber.length == 12) {
        // Check if first 2 digits are '91', if not add '91' prefix
        if (!mobileNumber.startsWith('91')) {
          formattedMobile = '91$mobileNumber';
        }
      }

      final message = Uri.encodeComponent(utmLink);
      final whatsappUrl = 'https://wa.me/$formattedMobile?text=$message';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch WhatsApp'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Fallback to clipboard if no mobile number
      await Clipboard.setData(ClipboardData(text: utmLink));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UTM link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _isValidMobile(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    if (str.length != 10) return false;
    return double.tryParse(str) != null;
  }
}
