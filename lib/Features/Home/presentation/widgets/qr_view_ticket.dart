import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/qrcode_cubit.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanTicketPage extends StatefulWidget {
  const QRScanTicketPage({super.key, required this.ticketId});

  final BigInt ticketId;

  @override
  State<QRScanTicketPage> createState() => _QRScanTicketPageState();
}

class _QRScanTicketPageState extends State<QRScanTicketPage> {
  String? barcode;
  bool _isProcessing = false;
  bool _isCompleting = false;

  Future<void> _completeTicketAssetLink(int assetId) async {
    if (_isCompleting) return;
    _isCompleting = true;
    final messenger = ScaffoldMessenger.of(context);
    final linkResult = await context
        .read<AssetsTicketsCubit>()
        .addAssetsAndTickets(
          assetsId: BigInt.from(assetId),
          ticketId: widget.ticketId,
        );
    if (!mounted) return;

    final linked = linkResult.fold(
      (failure) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        return false;
      },
      (_) => true,
    );
    if (!linked) {
      setState(() {
        _isCompleting = false;
        _isProcessing = false;
      });
      return;
    }

    final responseResult = await context
        .read<TicketsCubit>()
        .updateTicketResponseDate(
          ticketId: widget.ticketId.toInt(),
          responseDate: DateTime.now(),
        );
    if (!mounted) return;
    responseResult.fold(
      (failure) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        setState(() {
          _isCompleting = false;
          _isProcessing = false;
        });
      },
      (_) => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(title: Text('Scan barcode/QR'.tr)),
      body: BlocConsumer<QrcodeCubit, QrcodeState>(
        listener: (context, state) {
          if (state is QrcodeSuccess) {
            _completeTicketAssetLink(state.assets.id);
          } else if (state is QrcodeFailed) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errMsg)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    MobileScanner(
                      fit: BoxFit.contain,
                      onDetect: (capture) {
                        if (_isProcessing || _isCompleting) return;
                        final values = capture.barcodes
                            .map((item) => item.rawValue)
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .toList(growable: false);
                        if (values.isEmpty) return;
                        final rawValue = values.first;
                        setState(() {
                          _isProcessing = true;
                          barcode = rawValue;
                        });
                        context.read<QrcodeCubit>().getAssetsByQrCode(rawValue);
                      },
                    ),
                    if (_isProcessing || _isCompleting)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    barcode == null ? 'Scan a code'.tr : '${'Result'.tr}: $barcode',
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
