import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/widgets/custom_profile_wedget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';
import '../../../../core/utils/widgets/custome_overview_widget.dart';
import '../../../../core/utils/widgets/ticket_overview_widget.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key, required this.user});

  final Users user;

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScaleFactorOf(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: screenHeight * 0.3,
                width: screenWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green, AppColors.lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              CustomBackShapeWedget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              CustomProfileWidget(
                screenWidth: screenWidth,
                image: "assets/images/user.png",
                name: '${widget.user.name}',
                position: '${widget.user.position!.name}',
                onPress: () {},
              ),
              BlocBuilder<TicketsCubit, TicketsState>(
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
                      totalTickets: state.tickets.length,
                      doneTickets: state.tickets
                          .where((ticket) => ticket.status == 'Completed')
                          .length,
                      awaitTickets: state.tickets
                          .where((ticket) => ticket.status == 'Awaiting')
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
              ),
            ],
          ),
        ),

        /// مسافة ديناميكية بدل 190px ثابتة
        SliverToBoxAdapter(
          child: SizedBox(height: screenHeight >= 600 ? 150 : 15),
        ),

        /// Tickets Overview Card
        SliverToBoxAdapter(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tickets Overview".tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// Tickets List
                  BlocBuilder<TicketsCubit, TicketsState>(
                    builder: (context, state) {
                      if (state is GetTicketsLoading) {
                        return const Center(
                          child:
                          CircularProgressIndicator(color: AppColors.green),
                        );
                      }
                      if (state is GetTicketsFailure) {
                        return Center(child: Text(state.errMsg));
                      }
                      if (state is GetTicketsSuccess &&
                          state.tickets.isNotEmpty) {
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.tickets.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin:
                              EdgeInsets.only(bottom: screenHeight * 0.04),
                              child: TicketOverViewWidget(
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                ticketData: state.tickets[index],
                              ),
                            );
                          },
                        );
                      }
                      return Column(
                        children: [
                          const Icon(Icons.inbox,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            "No Tickets Found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
