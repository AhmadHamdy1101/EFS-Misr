import 'package:efs_misr/Features/Assets_data/presentation/controller/qrcode_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../Assets_data/presentation/screens/assets_details_page.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String? barcode;
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(title: Text('Scan barcode/QR'.tr)),
      body: BlocConsumer<QrcodeCubit, QrcodeState>(
        // Only results for a scan started on this page; the cubit is shared.
        listenWhen: (_, _) => isProcessing,
        listener: (context, state) async {
          if (state is QrcodeSuccess) {
            // Stay locked while the details page is open, so the camera
            // behind it can't push the same page again.
            await Get.to(() => AssetsDetailsPage(assets: state.assets));
            if (mounted) setState(() => isProcessing = false);
          }
          if (state is QrcodeFailed) {
            Get.snackbar(
              'Error'.tr,
              state.errMsg,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            if (mounted) setState(() => isProcessing = false);
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
                  // One lookup per scan: a capture can hold several codes,
                  // and the camera reports the same code many times a second.
                  onDetect: (BarcodeCapture capture) {
                    if (isProcessing) return;
                    final value = capture.barcodes
                        .map((item) => item.rawValue)
                        .whereType<String>()
                        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
                    if (value.isEmpty) return;
                    setState(() {
                      isProcessing = true;
                      barcode = value;
                    });
                    context.read<QrcodeCubit>().getAssetsByQrCode(value);
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    barcode != null
                        ? '${'Result'.tr}: $barcode'
                        : 'Scan a code'.tr,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
