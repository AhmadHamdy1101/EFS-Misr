import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/models/assets.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/Functions/Capitalize_Function.dart';
import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../Assets_data/presentation/controller/assets_repair_cubit.dart';

class AddAssetsToTicketsDialog extends StatelessWidget {
   AddAssetsToTicketsDialog({
    super.key,
    required this.comment,
    required this.selectedValue,
    required this.selectedRepairValue,
    required this.amount, required this.ticket, required this.asset,
  });

  final TextEditingController comment;
  final String? selectedValue;
  final Tickets ticket;
 final Assets asset;
  final RxString selectedRepairValue;
  final TextEditingController amount;
  final List<Map<String, String>> data = [
    {'name': 'Spare Parts', 'value': 'Spare Parts'},
    {'name': 'No Spare Parts', 'value': 'No Spare Parts'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 20,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 3),
            Text(
              capitalizeEachWord('add Cost'),
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.green),
            ),
            CustomInputWidget(
              inbutIcon: 'assets/images/id.svg',
              iconColor: AppColors.green,
              inbutHintText: 'Comment',
              changeToPass: false,
              textEditingController: comment,
            ),
            CustomDropdownWidget(
              inbutIcon: 'assets/images/repair.svg',
              iconColor: AppColors.green,
              inbutHintText: 'Repair Type',
              selectedValue: selectedValue,
              Data: data,
              onChanged: (value) {
                selectedRepairValue.value = value!;
              },
            ),
            CustomInputWidget(
              inbutIcon: 'assets/images/deductions.svg',
              iconColor: AppColors.green,
              inbutHintText: 'Amount',
              changeToPass: false,
              textEditingController: amount,
            ),
            SizedBox(
              width: ScreensSize(context).screenWidth,
              child: CustomButtonWidget(
                toppadding: 10,
                onpressed: () async {
                  context.read<AssetsRepairCubit>().addAssetsRepair(
                    variation: selectedRepairValue.value,
                    comment: comment.text,
                    assetsId: asset.id,
                    ticketId: ticket.id,
                    amount: num.parse(amount.text),
                  );
                  await context
                      .read<AssetsRepairCubit>()
                      .getAssetsRepairDetails(ticketID: ticket.id, assetID: asset.id);
                },
                text: 'Add',
                foregroundcolor: Theme.of(
                  context,
                ).buttonTheme.colorScheme?.primary,
                color: Theme.of(context).buttonTheme.colorScheme?.secondary,
                textstyle: AppTextStyle.latoBold20(context),
                screenWidth: ScreensSize(context).screenWidth * 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
