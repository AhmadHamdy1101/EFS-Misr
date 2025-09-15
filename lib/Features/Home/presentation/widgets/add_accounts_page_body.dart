import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AddAccountPageBody extends StatefulWidget {
  const AddAccountPageBody({super.key});

  @override
  State<AddAccountPageBody> createState() => _AddAccountPageBodyState();
}

class _AddAccountPageBodyState extends State<AddAccountPageBody> {
  @override
  Widget build(BuildContext context) {
    String? selectedValue;
    final company = [
      {
        'name': 'EFS',
        'value': 'EFS',
      },
      {
        'name': 'Bank Misr',
        'value': 'Bank Misr',
      },

    ];
    final role = [
      {
        'name': 'Admin',
        'value': '1',
      },
      {
        'name': 'User',
        'value': '2',
      },
    ];
    final  status = [
      {
        'name': 'Active',
        'value': '1',
      },
      {
        'name': 'Intership',
        'value': '2',
      },
      {
        'name': 'Terminated',
        'value': '3',
      },
      {
        'name': 'Suspended',
        'value': '4',
      },
    ];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final TextEditingController username = TextEditingController();
    final TextEditingController password = TextEditingController();
    final TextEditingController email = TextEditingController();
    final TextEditingController companyEmail = TextEditingController();
    final TextEditingController address = TextEditingController();
    final TextEditingController phone = TextEditingController();
    final TextEditingController Status = TextEditingController();
    final TextEditingController Postition = TextEditingController();
    final TextEditingController Company = TextEditingController();
    final TextEditingController Role = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        centerTitle: true,
        title: Text(
          'Add Accounts'.tr,
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
                  CustomInputWidget(inbutIcon: 'assets/images/profile.svg', inbutHintText: 'Username', changeToPass: false, textEditingController: username),
                  CustomInputWidget(inbutIcon: 'assets/images/Password.svg', inbutHintText: 'Password', changeToPass: false, textEditingController: password),
                  CustomInputWidget(inbutIcon: 'assets/images/Email.svg', inbutHintText: 'Email', changeToPass: false, textEditingController: email),
                  CustomInputWidget(inbutIcon: 'assets/images/Email.svg', inbutHintText: 'Company Email', changeToPass: false, textEditingController: companyEmail),
                  CustomInputWidget(inbutIcon: 'assets/images/address.svg', inbutHintText: 'Address', changeToPass: false, textEditingController: address),
                  CustomInputWidget(inbutIcon: 'assets/images/phone.svg', inbutHintText: 'Phone', changeToPass: false, textEditingController: phone),
                  CustomDropdownWidget(inbutIcon: 'assets/images/Status.svg', inbutHintText: 'Status', textEditingController: Status, selectedValue: selectedValue, Data: status),
                  CustomDropdownWidget(inbutIcon: 'assets/images/position.svg', inbutHintText: 'Position', textEditingController: Postition, selectedValue: selectedValue, Data: status),
                  CustomDropdownWidget(inbutIcon: 'assets/images/company.svg' , inbutHintText: 'Company', textEditingController: Company, selectedValue: selectedValue, Data: company),
                  CustomDropdownWidget(inbutIcon: 'assets/images/role.svg' , inbutHintText: 'Role', textEditingController: Role, selectedValue: selectedValue, Data: role),
                  Container(
                    width: screenWidth,
                    child: ElevatedButton(
                        style: ButtonStyle( padding:WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 20)),backgroundColor: WidgetStatePropertyAll(AppColors.green),foregroundColor: WidgetStatePropertyAll(AppColors.white)),
                        onPressed: () {

                    }, child: Text('Add',style: AppTextStyle.latoBold26(context),)),
                  )

                ],
              ),
            ),
          )
        ],


      ),
    );
  }
}