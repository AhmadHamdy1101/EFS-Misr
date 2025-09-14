

import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';


import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../../../../core/utils/widgets/ticket_overview_widget.dart';
import '../pages/ticket_details_page.dart';




class TicketPageBody extends StatelessWidget {
  const TicketPageBody({super.key});


  // design here
  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController search = TextEditingController();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return BlocConsumer<TicketsCubit, TicketsState>(
      listener: (context, state) {

      },
      builder: (context, state) {

        if (state is GetTicketsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is GetTicketsFailure) {
          return Center(child: Text(state.errMsg));
        }
        if (state is GetTicketsSuccess) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: Form(
                    key: formKey,
                    child: Column(
                      spacing: 40,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CustomInputWidget(
                            inbutIcon: 'assets/images/search.svg',
                            inbutHintText: 'Search'.tr,
                            changeToPass: false,
                            textEditingController: search,
                            textInputType: TextInputType.emailAddress,
                            onChanged: (search) {
                              return context.read<TicketsCubit>().searchTickets(search);
                            },
                          ),
                        ),

                        SizedBox(
                          height: 1,
                        ),


                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () { }, child: Row(spacing:10,children: [ SvgPicture.asset('assets/images/Excel.svg'), Text('Export',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green),)],)),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child:  ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: state.tickets.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Get.to(TicketDetailsPage(tickets: state.tickets[index]));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          color: AppColors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: TicketOverViewWidget(
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              ticketData: state.tickets[index],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          );
        }
        return const Center(child: Text("No Tickets Found"));
      },
    );
  }
}
//
// Future<void> exportDataToExcel(BuildContext context) async {
//   try {
//     final supabase = Supabase.instance.client;
//
//     // هات البيانات من جدول tickets
//     final response = await supabase.from('tickets').select();
//
//     if (response.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("لا يوجد بيانات للتصدير")),
//       );
//       return;
//     }
//
//     // اعمل ملف Excel جديد
//     var excel = Excel.createExcel();
//     Sheet sheet = excel['Tickets'];
//
//     // اضف العناوين
//     final headers = response.first.keys.toList();
//     sheet.appendRow(headers);
//
//     // اضف الصفوف
//     for (var row in response) {
//       sheet.appendRow(row.values.toList());
//     }
//
//     // encode() بيرجع List<int>? فنعمله check
//     final fileBytes = excel.encode();
//     if (fileBytes == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("فشل إنشاء الملف")),
//       );
//       return;
//     }
//
//     // نحول List<int> → Uint8List
//     final Uint8List uint8list = Uint8List.fromList(fileBytes);
//
//     // نحفظ الملف
//     await FileSaver.instance.saveFile(
//       name: "tickets_export",
//       fileExtension: "xlsx",
//       // نحول ونأمنها من null
//       bytes: fileBytes,
//       mimeType: MimeType.microsoftExcel,
//     );
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("✅ تم حفظ الملف في Downloads")),
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("خطأ أثناء التصدير: $e")),
//     );
//   }
// }