import 'package:efs_misr/Features/Home/presentation/viewmodel/qrcode_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../pages/assets_details_page.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String? barcode;
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.AppBackground,
      appBar: AppBar(title: Text('Scan barcode/QR')),
      body: BlocConsumer<QrcodeCubit, QrcodeState>(
        listener: (context, state) {
          if (state is QrcodeSuccess) {
            Get.to(AssetsDetailsPage(assets: state.assets,));
          }
          if (state is QrcodeFailed) {
            Get.snackbar('Error', state.errMsg,backgroundColor: Colors.red,colorText: Colors.white);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                flex: 4,
                child: MobileScanner(
                  fit: BoxFit.contain,
                  // allowDuplicates: true,
                  onDetect: (BarcodeCapture capture) async {
                    if (isProcessing) return;
                    isProcessing = true;
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        context.read<QrcodeCubit>().getAssetsByQrCode(barcode.rawValue!);
                      }
                    }
                    Future.delayed(const Duration(seconds: 2), () {
                      isProcessing = false;
                    });
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                      barcode != null ? 'Result: $barcode' : 'Scan a code'),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
