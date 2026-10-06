import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controller/tickets_cubit.dart';

class TicketDamageComment extends StatelessWidget {
  const TicketDamageComment({
    super.key,
    required this.damageComment,
    required this.ticket,
  });

  final TextEditingController damageComment;
  final Tickets ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(20.0),
        width: ScreensSize(context).screenWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Damage Description:'.tr,
                  style: AppTextStyle.latoBold20(
                    context,
                  ).copyWith(color: AppColors.green),
                ),

                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 10,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,

                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [CloseButton()],
                                  ),

                                  CustomInputWidget(
                                    inbutIcon: "assets/images/comment.svg",
                                    inbutHintText: "Damage Description",
                                    changeToPass: false,
                                    textEditingController: damageComment,
                                  ),
                                  CustomButtonWidget(
                                    screenWidth: ScreensSize(
                                      context,
                                    ).screenWidth,
                                    toppadding: 10.0,
                                    textstyle: AppTextStyle.latoBold20(context),
                                    foregroundcolor: AppColors.white,
                                    onpressed: () {
                                      context
                                          .read<TicketsCubit>()
                                          .updateTicketComment(
                                            ticketId: ticket.id.toString(),
                                            newComment: damageComment.text,
                                          );
                                      Navigator.pop(
                                        context,
                                      );
                                    },
                                    text: 'Submit',
                                    color: AppColors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Edit',
                    style: AppTextStyle.latoBold20(
                      context,
                    ).copyWith(color: AppColors.gray),
                  ),
                ),
              ],
            ),
            BlocBuilder<TicketsCubit, TicketsState>(
              builder: (context, state) {
                if (state is GetTicketsSuccess) {
                  final currentTicket = state.tickets.firstWhere(
                    (t) => t.id == ticket.id,
                    orElse: () => ticket,
                  );
                  return Text(currentTicket.damageDescription ?? 'No Damage');
                }
                return Text(ticket.damageDescription ?? 'No Damage');
              },
            ),
          ],
        ),
      ),
    );
  }
}
