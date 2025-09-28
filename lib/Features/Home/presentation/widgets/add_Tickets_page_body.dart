import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    hide DatePickerTheme;
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_button_widget.dart';
import '../viewmodel/tickets_cubit.dart';

class AddTicketsPageBody extends StatefulWidget {
  const AddTicketsPageBody({super.key});

  @override
  State<AddTicketsPageBody> createState() => _AddTicketsPageBodyState();
}

class _AddTicketsPageBodyState extends State<AddTicketsPageBody> {
  final engineersData = <Map<String, dynamic>>[].obs;
  final branchesData = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    loadEngineers();
    loadBranches();
  }

  Future<void> loadEngineers() async {
    final engineers = await supabaseClient.users.select().filter(
      'positions',
      'eq',
      3,
    );
    engineersData.value = engineers.map<Map<String, dynamic>>((eng) {
      return {"name": eng["name"], "value": eng["id"].toString()};
    }).toList();
  }

  Future<void> loadBranches() async {
    final branches = await supabaseClient.branch.select();
    branchesData.value = branches.map<Map<String, dynamic>>((br) {
      return {"name": br["name"], "value": br["id"].toString()};
    }).toList();
  }
  String? selectedValue;

  final priorityData = [
    {'name': 'A', 'value': 'A'},
    {'name': 'B', 'value': 'B'},
    {'name': 'C', 'value': 'C'},
    {'name': 'D', 'value': 'D'},
  ];
  final selectedBranchID = BigInt.zero.obs;
  final selectedPriority = ''.obs;
  final selectedEngineer = BigInt.zero.obs;

  final TextEditingController oricalid = TextEditingController();
  final TextEditingController branch = TextEditingController();
  final Rx<DateTime> requestDate = DateTime.now().obs;
  final TextEditingController requestDateText = TextEditingController();
  final TextEditingController priority = TextEditingController();
  final TextEditingController comment = TextEditingController();
  final TextEditingController engineer = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            centerTitle: true,
            title: Text(
              'Add Ticket'.tr,
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.green),
            ),
          ),
          SliverToBoxAdapter(
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
                  Obx(() {
                    return CustomDropdownWidget(
                      inbutIcon: 'assets/images/company.svg',
                      inbutHintText: 'Branch',
                      textEditingController: branch,
                      selectedValue: selectedValue,
                      onChanged: (value) {
                        selectedBranchID.value = BigInt.tryParse(value!)!;
                      },
                      Data: branchesData.value,
                    );
                  },),
                  CustomDropdownWidget(
                    inbutIcon: 'assets/images/priority.svg',
                    inbutHintText: 'Priority',
                    textEditingController: priority,
                    selectedValue: selectedValue,
                    Data: priorityData,
                    onChanged: (value) {
                      selectedPriority.value = value!;
                    },
                  ),
                  CustomInputWidget(
                    inbutIcon: 'assets/images/date.svg',
                    inbutHintText: 'Request Date',
                    changeToPass: false,
                    readOnly: true,
                    textEditingController: requestDateText,
                    onTap: () async {
                      await DatePicker.showDatePicker(
                        context,
                        showTitleActions: true,
                        minTime: DateTime(2025),
                        maxTime: DateTime(2050),
                        onConfirm: (date) {
                          requestDateText.text = date.toString();
                          requestDate.value = date;
                        },
                        currentTime: DateTime.now(),
                        locale: LocaleType.en,
                      );
                    },
                  ),
                  CustomInputWidget(
                    inbutIcon: 'assets/images/comment.svg',
                    inbutHintText: 'Comment',
                    changeToPass: false,
                    textEditingController: comment,
                    textInputType: TextInputType.text,
                  ),
                  Obx(() {
                    return CustomDropdownWidget(
                      inbutIcon: 'assets/images/engineer.svg',
                      inbutHintText: 'Engineer',
                      textEditingController: engineer,
                      selectedValue: selectedValue,
                      Data: engineersData.value,
                      onChanged: (value) {
                        selectedEngineer.value = BigInt.tryParse(value!)!;
                      },
                    );
                  }),
                  SizedBox(
                    width: screenWidth,
                    child: CustomButtonWidget(
                      screenWidth: screenWidth,
                      color: AppColors.green,
                      text: 'Add Ticket',
                      onpressed: () {
                        context.read<TicketsCubit>().addTicket(
                          branchID: selectedBranchID.value,
                          comment: comment.text,
                          orecalID: BigInt.parse(oricalid.text),
                          priority: selectedPriority.value,
                          requestDate: requestDate.value,
                          engineer: selectedEngineer.value,
                        );
                      },
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
