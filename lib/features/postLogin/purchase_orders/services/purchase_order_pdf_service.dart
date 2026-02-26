import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_items/model/po_item_model.dart';
import '../model/purchase_order_model.dart';
import 'pdf_asset_loader.dart';
import 'pdf_data_processor.dart';

// Internal models moved to pdf_data_processor.dart

class PurchaseOrderPdfService {
  static Future<Uint8List> generateBillPdf(
    List<ModelPurchaseOrder> orders,
    List<List<ModelPoItem>> allItems,
    EntityAdapter<ModelPurchaseOrder> adapter, {
    Map<String, bool>? splitPreferences,
  }) async {
    final assets = await PdfAssetLoader.load();
    final cardParts = PdfDataProcessor.processForBillPdf(
      orders: orders,
      allItems: allItems,
      splitPreferences: splitPreferences,
    );

    final pdf = Document(
      theme: ThemeData.withFont(base: assets.regular, bold: assets.bold),
    );

    final int cardsPerPage = 4;

    for (int i = 0; i < cardParts.length; i += cardsPerPage) {
      final chunkParts = cardParts.sublist(
        i,
        (i + cardsPerPage) > cardParts.length
            ? cardParts.length
            : i + cardsPerPage,
      );

      pdf.addPage(
        Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const EdgeInsets.all(8),
          build: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (int j = 0; j < chunkParts.length; j++) ...[
                      if (j > 0) SizedBox(width: 8),
                      Expanded(
                        child: _buildOrderCard(
                          chunkParts[j].order,
                          chunkParts[j].items,
                          adapter,
                          assets.regular,
                          assets.bold,
                          assets.logo,
                          chunkParts[j].globalIndex,
                          partIndex: chunkParts[j].partIndex,
                          totalParts: chunkParts[j].totalParts,
                        ),
                      ),
                    ],
                    // Fill remaining space if less than 4 cards on the page
                    for (int k = chunkParts.length; k < cardsPerPage; k++) ...[
                      if (k > 0) SizedBox(width: 8),
                      Expanded(child: Container()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  static Widget _buildOrderCard(
    ModelPurchaseOrder order,
    List<ModelPoItem> items,
    EntityAdapter<ModelPurchaseOrder> adapter,
    Font font,
    Font boldFont,
    MemoryImage logoImage,
    int index, {
    int partIndex = 1,
    int totalParts = 1,
  }) {
    final shopName =
        adapter
            .getLabelValue(order, ModelPurchaseOrderFields.poShopId)
            ?.toString() ??
        'Unknown Shop';
    final routeName =
        adapter
            .getLabelValue(order, ModelPurchaseOrderFields.poRouteId)
            ?.toString() ??
        'Unknown Route';
    final amount =
        order.poTotalAmount ?? 0.0; // Always round up to the next integer
    final roundedUp = amount.ceil(); // Convert to string without decimals
    final totalAmount = roundedUp.toString();
    final itemCount = order.poLineItemCount ?? 0;

    // Item numbering offset based on partIndex
    const int maxItemsPerCard = 15;
    final int itemOffset = (partIndex - 1) * maxItemsPerCard;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: PdfColors.grey300),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(font: font),
                    children: [
                      TextSpan(
                        text: 'Rasoia Sales : ',
                        style: TextStyle(
                          font: font,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: '94 21 58 21 62',
                        style: TextStyle(font: boldFont, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Save number for : Orders | Expiry | Enquiry",
                  style: TextStyle(font: font, fontSize: 7),
                ),
              ),
            ],
          ),

          Divider(color: PdfColors.grey400),
          // Shop Logo
          Container(
            width: double.infinity,
            child: Image(
              logoImage,
              fit: BoxFit.contain, // or BoxFit.cover / BoxFit.fitWidth
            ),
          ),

          // Shop Info Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$index. ',
                        style: TextStyle(font: boldFont, fontSize: 10),
                      ),
                      TextSpan(
                        text: totalParts > 1
                            ? '$shopName (Part $partIndex/$totalParts)'
                            : shopName,
                        style: TextStyle(font: boldFont, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Route: $routeName',
                  style: TextStyle(font: font, fontSize: 8),
                ),
                SizedBox(height: 2),
                Text(
                  'Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}',
                  style: TextStyle(font: font, fontSize: 8),
                ),
                SizedBox(height: 2),
                Text(
                  'Address: ${adapter.getLabelValue(order, 'shop_address')?.toString() ?? ''}',
                  style: TextStyle(font: font, fontSize: 8),
                ),
                SizedBox(height: 2),
                Text(
                  'Note 1: ${adapter.getLabelValue(order, 'shop_note')?.toString() ?? '-'}',
                  style: TextStyle(font: font, fontSize: 8),
                ),
                SizedBox(height: 2),
                Text(
                  'Note 2: ${order.userComment ?? ''}',
                  style: TextStyle(font: font, fontSize: 8),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Divider(color: PdfColors.grey400),
          SizedBox(height: 2),
          Table(
            border: TableBorder.all(color: PdfColors.grey200),
            columnWidths: {
              0: const IntrinsicColumnWidth(),
              1: const FlexColumnWidth(),
              2: const IntrinsicColumnWidth(),
              3: const IntrinsicColumnWidth(),
              4: const IntrinsicColumnWidth(),
              5: const IntrinsicColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: PdfColors.cyan),
                children: [
                  _buildTableCell(
                    '#',
                    boldFont,
                    alignRight: true,
                    padding: const EdgeInsets.all(3),
                  ),
                  _buildTableCell(
                    'Item Name',
                    boldFont,
                    padding: const EdgeInsets.all(3),
                  ),
                  _buildTableCell(
                    'Wgt',
                    boldFont,
                    alignRight: true,
                    padding: const EdgeInsets.all(3),
                  ),
                  _buildTableCell(
                    'Qty',
                    boldFont,
                    alignRight: true,
                    padding: const EdgeInsets.all(3),
                  ),
                  _buildTableCell(
                    'Rate',
                    boldFont,
                    alignRight: true,
                    padding: const EdgeInsets.all(3),
                  ),
                  _buildTableCell(
                    'Amount',
                    boldFont,
                    alignRight: true,
                    padding: const EdgeInsets.all(3),
                  ),
                ],
              ),
              ...items
                  .toList()
                  .asMap()
                  .map(
                    (idx, item) => MapEntry(
                      idx,
                      TableRow(
                        children: [
                          _buildTableCell(
                            '${itemOffset + idx + 1}',
                            font,
                            alignRight: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                          ),
                          _buildTableCell(
                            item.itemName ?? 'Unknown',
                            font,
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                          ),
                          _buildTableCell(
                            '${item.resolvedLabels['product_weight_value_label'] ?? ''}${(item.resolvedLabels['product_weight_unit_label'] ?? '').toString().replaceAll('gms', 'g')}',
                            font,
                            fontSize: 7,
                            alignRight: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                          ),
                          _buildTableCell(
                            _formatQuantity(item.itemQty),
                            boldFont,
                            alignRight: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                          ),
                          _buildTableCell(
                            item.itemSellRate?.toStringAsFixed(2) ?? '-0',
                            font,
                            fontSize: 7,
                            alignRight: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                          ),
                          _buildTableCell(
                            item.itemPrice?.toStringAsFixed(2) ?? '-0',
                            font,
                            alignRight: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .values,
            ],
          ),
          if (partIndex == totalParts) ...[
            SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items: $itemCount',
                    style: TextStyle(font: font, fontSize: 10),
                  ),
                  Text(
                    'Total:  ₹$totalAmount',
                    style: TextStyle(font: boldFont, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatQuantity(dynamic qty) {
    if (qty == null) return '-';
    final quantity = double.tryParse(qty.toString()) ?? 0.0;
    final rounded = quantity.round();
    if (quantity == rounded) {
      return rounded.toString();
    } else {
      return quantity.toStringAsFixed(1);
    }
  }

  static Future<Uint8List> generateCollectionSheetPdf(
    List<ModelPurchaseOrder> orders,
    EntityAdapter<ModelPurchaseOrder> adapter,
  ) async {
    final assets = await PdfAssetLoader.load();
    final processResult = PdfDataProcessor.processRouteGrouping(
      orders: orders,
      adapter: adapter,
    );

    final ordersByRoute = processResult.ordersByRoute;
    final sortedRoutes = processResult.sortedRoutes;

    final pdf = Document(
      theme: ThemeData.withFont(base: assets.regular, bold: assets.bold),
    );

    // Shared column widths for alignment across headers and data tables
    const columnWidths = {
      0: FixedColumnWidth(20), // #
      1: FlexColumnWidth(1), // Shop Name
      2: FixedColumnWidth(45), // Bill Amount
      3: FixedColumnWidth(45), // Collected Amount
      4: FixedColumnWidth(35), // Cash
      5: FixedColumnWidth(35), // Online
      6: FixedColumnWidth(38), // Cheque
      7: FixedColumnWidth(60), // Cheque No
      8: FixedColumnWidth(40), // Sign
      9: FixedColumnWidth(50), // Sign Amount
      10: FlexColumnWidth(2), // Comments
    };

    // Width for the merged "Collection Mode" header (Cash + Online + Cheque)
    const double collectionModeWidth = 35.0 + 35.0 + 38.0;

    pdf.addPage(
      MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const EdgeInsets.all(20),
        header: (context) {
          return Column(
            children: [
              // Page Main Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collection Sheet',
                    style: TextStyle(font: assets.bold, fontSize: 18),
                  ),
                  Text(
                    'Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}',
                    style: TextStyle(font: assets.bold, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Table Groups Header (Merged Cells)
              Table(
                border: TableBorder(
                  left: BorderSide(color: PdfColors.grey300),
                  right: BorderSide(color: PdfColors.grey300),
                  top: BorderSide(color: PdfColors.grey300),
                  bottom: BorderSide.none, // Connect to next table
                  verticalInside: BorderSide(color: PdfColors.grey300),
                  horizontalInside: BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: {
                  ...columnWidths,
                  4: const FixedColumnWidth(
                    collectionModeWidth,
                  ), // Override for merged column (Cash + Online + Cheque)
                  5: const FixedColumnWidth(
                    0,
                  ), // Hidden Online column (covered by merged)
                  6: const FixedColumnWidth(
                    0,
                  ), // Hidden Cheque column (covered by merged)
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: PdfColors.grey200),
                    children: [
                      Container(padding: const EdgeInsets.all(2)), // # (0)
                      Container(padding: const EdgeInsets.all(2)), // Shop (1)
                      Container(padding: const EdgeInsets.all(2)), // Bill (2)
                      Container(
                        padding: const EdgeInsets.all(2),
                      ), // Collected (3)
                      // Merged Column for Collection Mode (4)
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          'Collection Mode',
                          style: TextStyle(font: assets.bold, fontSize: 8),
                        ),
                      ),

                      Container(), // Dummy for Online (5) - Width 0
                      Container(), // Dummy for Cheque (6) - Width 0

                      Container(
                        padding: const EdgeInsets.all(2),
                      ), // Cheque No (7)
                      Container(padding: const EdgeInsets.all(2)), // Sign (8)
                      Container(
                        padding: const EdgeInsets.all(2),
                      ), // Sign Amt (9)
                      Container(
                        padding: const EdgeInsets.all(2),
                      ), // Comments (10)
                    ],
                  ),
                ],
              ),

              // Table Specific Headers
              Table(
                border: TableBorder(
                  left: BorderSide(color: PdfColors.grey300),
                  right: BorderSide(color: PdfColors.grey300),
                  top: BorderSide(
                    color: PdfColors.grey300,
                  ), // Sep from Group Header
                  bottom: BorderSide(color: PdfColors.grey300), // Sep from Data
                  verticalInside: BorderSide(color: PdfColors.grey300),
                  horizontalInside: BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: PdfColors.grey200),
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildTableCell('#', assets.bold, alignCenter: true),
                      _buildTableCell('Shop Name', assets.bold),
                      _buildTableCell(
                        'Bill Amount',
                        assets.bold,
                        alignRight: true,
                      ),
                      _buildTableCell(
                        'Collected Amount',
                        assets.bold,
                        alignRight: true,
                      ),
                      // Specific Collection Modes
                      _buildTableCell('Cash', assets.bold, alignCenter: true),
                      _buildTableCell('Online', assets.bold, alignCenter: true),
                      _buildTableCell('Cheque', assets.bold, alignCenter: true),
                      _buildTableCell('Cheque No', assets.bold),
                      // Sign
                      _buildTableCell('Sign', assets.bold, alignCenter: true),
                      _buildTableCell('Sign Amount', assets.bold),
                      _buildTableCell('Comments', assets.bold),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            ...sortedRoutes.expand((route) {
              final routeOrders = ordersByRoute[route]!;

              return [
                // Route Header Separator
                Container(
                  width: double.infinity,
                  color: PdfColors.blueGrey100,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 20,
                  ),
                  child: Text(
                    route,
                    style: TextStyle(font: assets.bold, fontSize: 10),
                  ),
                ),
                // Data Table for this Route
                Table(
                  border: TableBorder(
                    left: BorderSide(color: PdfColors.grey300),
                    right: BorderSide(color: PdfColors.grey300),
                    top: BorderSide.none, // Connected to header
                    bottom: BorderSide(color: PdfColors.grey300),
                    verticalInside: BorderSide(color: PdfColors.grey300),
                    horizontalInside: BorderSide(color: PdfColors.grey300),
                  ),
                  columnWidths: columnWidths,
                  children: routeOrders.map((order) {
                    final shopName =
                        adapter
                            .getLabelValue(
                              order,
                              ModelPurchaseOrderFields.poShopId,
                            )
                            ?.toString() ??
                        'Unknown';
                    final amountRaw = order.poTotalAmount ?? 0;
                    final amountStr = '₹ ${amountRaw.ceil()}';

                    return TableRow(
                      children: [
                        _buildTableCell(
                          (orders.indexOf(order) + 1).toString(),
                          assets.regular,
                          alignCenter: true,
                        ),
                        _buildTableCell(shopName, assets.regular),
                        _buildTableCell(
                          amountStr,
                          assets.bold,
                          alignRight: true,
                        ),
                        _buildTableCell('', assets.regular), // Collected
                        _buildTableCell('', assets.regular), // Cash
                        _buildTableCell('', assets.regular), // Online
                        _buildTableCell('', assets.regular), // Cheque
                        _buildTableCell('', assets.regular), // Cheque No
                        _buildTableCell('', assets.regular), // Sign
                        _buildTableCell('', assets.regular), // Sign Amt
                        _buildTableCell('', assets.regular), // Comments
                      ],
                    );
                  }).toList(),
                ),
              ];
            }),
            // Total Row Table
            Table(
              border: TableBorder(
                left: BorderSide(color: PdfColors.grey300),
                right: BorderSide(color: PdfColors.grey300),
                top: BorderSide.none,
                bottom: BorderSide(color: PdfColors.grey300),
                verticalInside: BorderSide(color: PdfColors.grey300),
                horizontalInside: BorderSide(color: PdfColors.grey300),
              ),
              columnWidths: columnWidths,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('', assets.regular),
                    _buildTableCell('Total', assets.bold, alignRight: true),
                    _buildTableCell(
                      '₹ ${orders.fold<double>(0, (sum, o) => sum + (o.poTotalAmount ?? 0)).ceil()}',
                      assets.bold,
                      alignRight: true,
                    ),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                    _buildTableCell('', assets.regular),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Widget _buildTableCell(
    String text,
    Font font, {
    bool alignRight = false,
    bool alignCenter = false,
    double fontSize = 8,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: TextStyle(font: font, fontSize: fontSize),
        textAlign: alignRight
            ? TextAlign.right
            : (alignCenter ? TextAlign.center : TextAlign.left),
      ),
    );
  }
}
