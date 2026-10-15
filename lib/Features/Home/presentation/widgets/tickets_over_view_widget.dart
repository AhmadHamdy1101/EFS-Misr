import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/widgets/custome_overview_widget.dart';
import '../../../Tickets/domain/entities/ticket_entity.dart';
import '../../../Tickets/presentation/controller/tickets_cubit.dart';

class TicketsOverViewWidget extends StatelessWidget {
  const TicketsOverViewWidget({
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
        if (state is GetTicketsSuccess) {
          return CustomOverviewWidget(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            totalTickets: state.allTickets.length,
            doneTickets: state.allTickets
                .where((ticket) => ticket.status == TicketStatus.completed)
                .length,
            awaitTickets: state.allTickets
                .where((ticket) => ticket.status == TicketStatus.awaiting)
                .length,
          );
        }
        return CustomOverviewWidget(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          totalTickets: 0,
          doneTickets: 0,
          awaitTickets: 0,
        );
      },
    );
  }
}
