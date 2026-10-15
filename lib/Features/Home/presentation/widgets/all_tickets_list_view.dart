import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../Tickets/presentation/controller/tickets_cubit.dart';
import '../../../Tickets/presentation/widgets/ticket_overview_widget.dart';

class AllTicketsListView extends StatelessWidget {
  const AllTicketsListView({
    super.key,
    required this.screenHeight,
    required this.screenWidth,
  });

  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        if (state is GetTicketsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }
        if (state is GetTicketsFailure) {
          return Center(child: Text(state.errMsg));
        }
        if (state is GetTicketsSuccess && state.allTickets.isNotEmpty) {
          final overviewTickets = state.allTickets.take(5).toList();
          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: overviewTickets.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.04),
                child: TicketOverViewWidget(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  ticketData: overviewTickets[index],
                ),
              );
            },
          );
        }
        return Column(
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 10),
            Text("No Tickets Found", style: TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }
}
