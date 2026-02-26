import 'package:intl/intl.dart';
import '../../products/product_barrel.dart';

class PoItemAddLogic {
  /// Formats quantity for display (removes .0 if present)
  static String formatQty(double val) {
    if (val == 0) return "";
    String text = val.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  /// Formats num value as currency (₹)
  static String formatCurrency(num value) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    ).format(value);
  }

  /// Calculates total price based on quantity and rate
  static double calculatePrice(double qty, double rate) {
    return qty * rate;
  }

  /// Gets the purchase rate for retailer from product, defaulting to 0.0
  static double getProductRate(ModelProduct? product) {
    return product?.purchaseRateForRetailer ?? 0.0;
  }

  /// Gets the MRP from product, defaulting to 0.0
  static double getProductMrp(ModelProduct? product) {
    return product?.mrp ?? 0.0;
  }
}
