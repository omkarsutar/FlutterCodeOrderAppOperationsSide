import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart';

class PdfAssets {
  final Font regular;
  final Font bold;
  final MemoryImage logo;

  PdfAssets({required this.regular, required this.bold, required this.logo});
}

class PdfAssetLoader {
  static Future<PdfAssets> load() async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final font = Font.ttf(fontData.buffer.asByteData());

    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final boldFont = Font.ttf(boldFontData.buffer.asByteData());

    // Load the shop logo image
    final logoData = await rootBundle.load(
      'assets/images/rasoiaImageUsedOnBill.png',
    );
    final logoImage = MemoryImage(logoData.buffer.asUint8List());

    return PdfAssets(regular: font, bold: boldFont, logo: logoImage);
  }
}
