import 'package:flutter/material.dart';
import '../model/purchase_order_model.dart';
import '../../../../core/services/entity_service.dart';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import to handle web-specific functionality safely
import 'dart:html' as html if (dart.library.io) 'dart:io';

class PurchaseOrderSharePreviewPage extends StatefulWidget {
  final ModelPurchaseOrder entity;
  final EntityAdapter<ModelPurchaseOrder> adapter;

  const PurchaseOrderSharePreviewPage({
    super.key,
    required this.entity,
    required this.adapter,
  });

  @override
  State<PurchaseOrderSharePreviewPage> createState() =>
      _PurchaseOrderSharePreviewPageState();
}

class _PurchaseOrderSharePreviewPageState
    extends State<PurchaseOrderSharePreviewPage> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<void> _shareScreenshot() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName = 'profit_summary_${widget.entity.poId ?? "order"}.png';

      if (kIsWeb) {
        // For Web/PWA, sharing files via Share API is often unreliable or unsupported.
        // A common and robust PWA pattern is to download the image.
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image downloaded for sharing!')),
          );
        }
      } else {
        // Native apps use share_plus which handles the internal file creation.
        await Share.shareXFiles(
          [XFile.fromData(pngBytes, name: fileName, mimeType: 'image/png')],
          subject: 'Order Profit Summary',
          text: 'Summary for ${widget.entity.poId ?? "order"} from Rasoia.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final shopName =
        widget.adapter
            .getLabelValue(widget.entity, ModelPurchaseOrderFields.poShopId)
            ?.toString() ??
        'Unknown Shop';
    final shopMobile =
        widget.entity.resolvedLabels['shop_mobile_label']?.toString() ?? '';

    final profitStr = (widget.entity.profitToShop ?? 0).ceil();
    final amountStr = (widget.entity.poTotalAmount ?? 0).ceil();
    final itemCount = widget.entity.poLineItemCount ?? 0;
    final poDate = widget.entity.updatedAt ?? widget.entity.createdAt ?? DateTime.now();
    final formattedDate = DateFormat('dd-MMM-yyyy').format(poDate);

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF4A148C),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // RepaintBoundary wraps the entire visual content including background
            Positioned.fill(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF4A148C), // Deep Purple
                        Color(0xFF311B92), // Deep Indigo
                        Color(0xFF1A237E), // Darker Blue
                      ],
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 40,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Date Row (Above Card)
                            _buildTopDateLabel(context, formattedDate),

                            const SizedBox(height: 16),

                            // Main Info Card
                            Card(
                              elevation: 20,
                              shadowColor: Colors.black.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Shop name
                                    Text(
                                      shopName,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF4A148C),
                                            letterSpacing: -1.0,
                                            fontSize: 28,
                                          ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Shop Mobile
                                    if (shopMobile.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E5F5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.phone_android,
                                              size: 16,
                                              color: Color(0xFF4A148C),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              shopMobile,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF4A148C,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 32),

                                    Divider(
                                      color: const Color(
                                        0xFF4A148C,
                                      ).withOpacity(0.1),
                                      thickness: 2,
                                    ),

                                    const SizedBox(height: 28),

                                    // Summary Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSummaryColumn(
                                          context,
                                          '',
                                          'Items',
                                          '$itemCount',
                                          fontWeight: FontWeight.w900,
                                        ),
                                        _buildSummaryColumn(
                                          context,
                                          '',
                                          'Bill Amount',
                                          '₹$amountStr',
                                          valueColor: const Color(0xFF0D47A1),
                                          fontWeight: FontWeight.w900,
                                          alignEnd: true,
                                        ),
                                        _buildSummaryColumn(
                                          context,
                                          'Shop Profit',
                                          'on MRP',
                                          '₹$profitStr',
                                          valueColor: const Color(0xFF1B5E20),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 60),

                            // Delivery Messages
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'आपकी Rasoia ऑर्डर डिलिव्हर हो चुकी है!',
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 36),
                                Text(
                                  'Congratulations!',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: const Color(
                                      0xFFA5D6A7,
                                    ), // Bright Light Green
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'आपने ₹$profitStr का Profit कमाया है। ',
                                  textAlign: TextAlign.center,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons (Top Left: Close, Top Right: Share)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button (Left)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Close',
                    ),
                  ),
                  // Share Button (Screenshot - Right)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _shareScreenshot,
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Share Screenshot',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDateLabel(BuildContext context, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        'Date: $date',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: const Color(0xFF4A148C),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(
    BuildContext context,
    String label1,
    String label2,
    String value, {
    Color? valueColor,
    FontWeight? fontWeight,
    bool alignEnd = false,
  }) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.grey[600],
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      height: 1.2,
    );

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        if (label1.isNotEmpty) Text(label1, style: labelStyle),
        if (label2.isNotEmpty) Text(label2, style: labelStyle),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: fontWeight ?? FontWeight.w900,
            color: valueColor ?? Colors.black,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
