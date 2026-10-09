import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/tickets_edit_pop_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../Assets_data/presentation/controller/assets_repair_cubit.dart';
import '../controller/tickets_cubit.dart';
import '../screens/ticket_details_page.dart';

class TicketsList extends StatelessWidget {
  const TicketsList({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: BlocBuilder<TicketsCubit, TicketsState>(
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
                    context.read<AssetsTicketsCubit>().getAssetsWithTicketId(
                      ticketId: state.tickets[index].id,
                    );
                    // context.read<AssetsRepairCubit>().getAssetsRepairDetails(
                    //   ticketID: state.tickets[index].id, assetID: ,
                    // );
                    Get.to(
                      () => TicketDetailsPage(tickets: state.tickets[index]),
                    );
                  },
                  child: TicketsEditPopMenu(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight, tickets: state.tickets[index],
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No Tickets Found"));
        },
      ),
    );
  }
}
