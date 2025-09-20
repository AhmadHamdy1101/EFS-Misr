import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_button_widget.dart';

class AddTicketsPageBody extends StatefulWidget {
  const AddTicketsPageBody({super.key});

  @override
  State<AddTicketsPageBody> createState() => _AddTicketsPageBodyState();
}

class _AddTicketsPageBodyState extends State<AddTicketsPageBody> {
  @override
  Widget build(BuildContext context) {
    String? selectedValue;
    final Branch = [
      {'name': 'Sarayat el Maadi', 'value': '3'},
    ];
    final priority = [
      {'name': 'A', 'value': 'A'},
      {'name': 'B', 'value': 'B'},
      {'name': 'C', 'value': 'C'},
      {'name': 'D', 'value': 'D'},
    ];
    final status = [
      {'name': 'Active', 'value': '1'},
      {'name': 'Intership', 'value': '2'},
      {'name': 'Terminated', 'value': '3'},
      {'name': 'Suspended', 'value': '4'},
    ];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final TextEditingController oricalid = TextEditingController();
    final TextEditingController branch = TextEditingController();
    final TextEditingController requestdate = TextEditingController();
    final TextEditingController Priority = TextEditingController();
    final TextEditingController comment = TextEditingController();
    final TextEditingController engineer = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Add Ticket'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                spacing: 20,
                children: [
                  CustomInputWidget(
                    inbutIcon: 'assets/images/id.svg',
                    inbutHintText: 'Orical Id',
                    changeToPass: false,
                    textEditingController: oricalid,
                    textInputType: TextInputType.number,
                  ),
                  CustomDropdownWidget(
                    inbutIcon: 'assets/images/company.svg',
                    inbutHintText: 'Branch',
                    textEditingController: branch,
                    selectedValue: selectedValue,
                    Data: Branch,
                  ),
                  CustomDropdownWidget(
                    inbutIcon: 'assets/images/priority.svg',
                    inbutHintText: 'Priority',
                    textEditingController: Priority,
                    selectedValue: selectedValue,
                    Data: priority,
                  ),
                  CustomInputWidget(
                    inbutIcon: 'assets/images/date.svg',
                    inbutHintText: 'Request Date',
                    changeToPass: false,
                    textEditingController: requestdate,
                    textInputType: TextInputType.datetime,
                  ),

                  CustomInputWidget(
                    inbutIcon: 'assets/images/comment.svg',
                    inbutHintText: 'Comment',
                    changeToPass: false,
                    textEditingController: comment,
                    textInputType: TextInputType.text,
                  ),
                  CustomDropdownWidget(
                    inbutIcon: 'assets/images/engineer.svg',
                    inbutHintText: 'Engineer',
                    textEditingController: engineer,
                    selectedValue: selectedValue,
                    Data: status,
                  ),
                  SizedBox(
                    width: screenWidth,
                    child: CustomButtonWidget(
                      screenWidth: screenWidth,
                      color: AppColors.green,
                      text: 'Add Ticket',
                      onpressed: () {},
                      foregroundcolor: AppColors.white,
                      textstyle: AppTextStyle.latoBold26(context),
                      toppadding: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
