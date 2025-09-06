import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/widgets/ticket_overview_widget.dart';
import '../pages/ticket_details_page.dart';


class TicketPageBody extends StatelessWidget {
  const TicketPageBody({super.key});

  // design here
  @override
  Widget build(BuildContext context) {
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
          return ListView.builder(
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
          );
        }
        return const Center(child: Text("No Tickets Found"));
      },
    );
  }
}
