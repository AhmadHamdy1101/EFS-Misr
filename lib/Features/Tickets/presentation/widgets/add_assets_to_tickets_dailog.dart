import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/Functions/capitalize_text_function.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../Assets_data/presentation/controller/assets_repair_cubit.dart';
import '../../../Assets_data/presentation/controller/assets_tickets_cubit.dart';

class AddAssetsToTicketsDialog extends StatelessWidget {
  AddAssetsToTicketsDialog({
    super.key,
    required this.comment,
    required this.selectedValue,
    required this.selectedRepairValue,
    required this.amount,
    required this.ticket,
    required this.asset,
    required this.scaffoldMessenger,
  });

  final TextEditingController comment;
  final String? selectedValue;
  final TicketEntity ticket;
  final AssetsEntity asset;
  final ScaffoldMessengerState scaffoldMessenger;
  final RxString selectedRepairValue;
  final TextEditingController amount;

  final List<Map<String, dynamic>> data = [
    {'name': 'Spare Parts', 'value': 'Spare Parts'},
    {'name': 'No Spare Parts', 'value': 'No Spare Parts'},
  ];

  void _showMessage(String message, {required Color backgroundColor}) {
    if (!scaffoldMessenger.mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 8),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? errorMessage;
    bool isSaving = false;

    return Dialog(
      child: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 20,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 3),
                Text(
                  capitalizeEachWord('add Cost'),
                  style: AppTextStyle.latoBold26(
                    dialogContext,
                  ).copyWith(color: AppColors.green),
                ),
                CustomInputWidget(
                  inbutIcon: AppImages.images.id.path,
                  iconColor: AppColors.green,
                  inbutHintText: 'Comment',
                  changeToPass: false,
                  textEditingController: comment,
                ),
                CustomDropdownWidget(
                  inbutIcon: AppImages.images.repair.path,
                  iconColor: AppColors.green,
                  inbutHintText: 'Repair Type',
                  selectedValue: selectedValue,
                  data: data,
                  onChanged: (value) {
                    if (value != null) selectedRepairValue.value = value;
                  },
                ),
                CustomInputWidget(
                  inbutIcon: AppImages.images.deductions.path,
                  iconColor: AppColors.green,
                  inbutHintText: 'Amount',
                  changeToPass: false,
                  textEditingController: amount,
                ),
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                SizedBox(
                  width: ScreensSize(dialogContext).screenWidth,
                  child: CustomButtonWidget(
                    toppadding: 10,
                    onpressed: isSaving
                        ? null
                        : () async {
                            final parsedAmount = num.tryParse(
                              amount.text.trim(),
                            );
                          final repairType = selectedRepairValue.value.trim();
                          if (repairType.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Select a repair type.';
                            });
                            return;
                          }
                            if (parsedAmount == null ||
                                !parsedAmount.isFinite ||
                                parsedAmount < 0) {
                              setDialogState(() {
                                errorMessage = 'Enter a valid amount.';
                              });
                              return;
                            }

                            final repairCubit = dialogContext
                                .read<AssetsRepairCubit>();
                            final assetsTicketsCubit = dialogContext
                                .read<AssetsTicketsCubit>();

                            setDialogState(() {
                              isSaving = true;
                              errorMessage = null;
                            });

                            try {
                              final result = await repairCubit.addAssetsRepair(
                                variation: repairType,
                                comment: comment.text.trim(),
                                assetsId: BigInt.from(asset.id),
                                ticketId: BigInt.from(ticket.id),
                                amount: parsedAmount,
                              );
                              if (!dialogContext.mounted) return;

                              final added = result.fold((failure) {
                                final message = failure.message.trim();
                                setDialogState(() {
                                  isSaving = false;
                                  errorMessage = message.isEmpty
                                      ? 'Repair was not saved. Check the Supabase RPC and permissions.'
                                      : message;
                                });
                                return false;
                              }, (_) => true);

                              if (!added) return;
                              await Future.wait([
                                repairCubit.getAssetsRepairDetailsWithAssetId(
                                  assetID: BigInt.from(asset.id),
                                ),
                                assetsTicketsCubit.getAssetsWithTicketId(
                                  ticketId: BigInt.from(ticket.id),
                                ),
                              ]);

                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              _showMessage(
                                'Repair added successfully.',
                                backgroundColor: AppColors.green,
                              );
                            } catch (error) {
                              if (!dialogContext.mounted) return;
                              final message = error.toString().trim();
                              setDialogState(() {
                                isSaving = false;
                                errorMessage = message.isEmpty
                                    ? 'Unexpected error while saving the repair.'
                                    : message;
                              });
                            }
                          },
                    text: 'Add',
                    foregroundcolor: Theme.of(
                      dialogContext,
                    ).buttonTheme.colorScheme?.primary,
                    color: Theme.of(
                      dialogContext,
                    ).buttonTheme.colorScheme?.secondary,
                    textstyle: AppTextStyle.latoBold20(dialogContext),
                    screenWidth: ScreensSize(dialogContext).screenWidth * 0.5,
                  ),
                ),
                if (isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: CircularProgressIndicator(
                      color: AppColors.green,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
