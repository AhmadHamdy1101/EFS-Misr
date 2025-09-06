import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/constants.dart';
import '../../data/models/assets.dart';
import '../pages/assets_details_page.dart';

class QRScanPage extends StatefulWidget {
  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String? barcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan barcode/QR')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              fit: BoxFit.contain,
              // allowDuplicates: true,

              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                                    // debugPrint('Barcode found! ${barcode.rawValue}');
                  setState(() {
                    this.barcode = barcode.rawValue;
                  });
                  final data = supabaseClient.from('assets').select().eq('barcode', barcode).single();
                  final asset = Assets.fromJson(data as Map<String, dynamic>);
                  Get.to(AssetsDetailsPage(assets: asset,));
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(barcode != null ? 'Result: $barcode' : 'Scan a code'),
            ),
          )
        ],
      ),
    );
  }
}
