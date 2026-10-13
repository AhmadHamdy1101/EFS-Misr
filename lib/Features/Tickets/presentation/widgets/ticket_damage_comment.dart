import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TicketDamageComment extends StatelessWidget {
  const TicketDamageComment({
    super.key,
    required this.damageComment,
    required this.ticket,
  });

  final TextEditingController damageComment;
  final TicketEntity ticket;

  Future<void> _editDamageDescription(BuildContext context) async {
    damageComment.text = ticket.damageDescription;
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    var errorMessage = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Edit damage description'.tr),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomInputWidget(
                  inbutIcon: 'assets/images/comment.svg',
                  inbutHintText: 'Damage Description'.tr,
                  changeToPass: false,
                  textEditingController: damageComment,
                  textInputType: TextInputType.multiline,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Damage description is required'.tr
                      : null,
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel'.tr),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        errorMessage = '';
                      });
                      final result = await dialogContext
                          .read<TicketsCubit>()
                          .updateDamageDescription(
                            ticketId: ticket.id,
                            damageDescription: damageComment.text.trim(),
                          );
                      if (!dialogContext.mounted) return;
                      result.fold(
                        (failure) => setDialogState(() {
                          isSaving = false;
                          errorMessage = failure.message;
                        }),
                        (_) => Navigator.pop(dialogContext),
                      );
                    },
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: ScreensSize(context).screenWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Damage Description:'.tr,
                      style: AppTextStyle.latoBold20(
                        context,
                      ).copyWith(color: AppColors.green),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _editDamageDescription(context),
                    child: Text(
                      'Edit'.tr,
                      style: AppTextStyle.latoBold20(
                        context,
                      ).copyWith(color: AppColors.gray),
                    ),
                  ),
                ],
              ),
              BlocBuilder<TicketsCubit, TicketsState>(
                builder: (context, state) {
                  final latest = state is GetTicketsSuccess
                      ? state.allTickets.firstWhere(
                          (item) => item.id == ticket.id,
                          orElse: () => ticket,
                        )
                      : ticket;
                  return Text(latest.damageDescription);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
