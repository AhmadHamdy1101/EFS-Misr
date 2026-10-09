import 'package:efs_misr/Features/Tickets/presentation/widgets/filter_section_widget.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/tickets_list.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../controller/tickets_cubit.dart';

class TicketPageBody extends StatefulWidget {
  const TicketPageBody({super.key});

  @override
  State<TicketPageBody> createState() => _TicketPageBodyState();
}

class _TicketPageBodyState extends State<TicketPageBody> {
  final TextEditingController search = TextEditingController();
  final List<Map<String, dynamic>> data = [
    {'name': 'North Cairo', 'value': 'North Cairo'},
    {'name': 'South Cairo', 'value': 'South Cairo'},
    {'name': 'Middle Cairo', 'value': 'Middle Cairo'},
    {'name': 'New Cairo', 'value': 'New Cairo'},
  ];
  String? selectedValue;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.8,
            child: Column(
              spacing: 40,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CustomInputWidget(
                    inbutIcon: AppImages.images.search.path,
                    inbutHintText: 'Search'.tr,
                    changeToPass: false,
                    textEditingController: search,
                    textInputType: TextInputType.text,
                    onChanged: (search) {
                       context.read<TicketsCubit>().searchTickets(search);
                       return null;
                    },
                  ),
                ),
                SizedBox(height: 1),
              ],
            ),
          ),
        ),
        FilterSectionWidget(
          selectedValue: selectedValue,
          Data: data,
          screenWidth: screenWidth,
        ),
        TicketsList(screenWidth: screenWidth, screenHeight: screenHeight),
      ],
    );
  }
}
