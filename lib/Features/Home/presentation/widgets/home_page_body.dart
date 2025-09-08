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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
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
              // شعار SVG على الخلفية
              CustomBackShapeWedget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              // عناصر البروفايل فوق الخلفية
              CustomProfileWidget(
                screenWidth: screenWidth,
                image: "assets/images/profile.jpg",
                name: '${widget.user.name}',
                position: '${widget.user.position!.name}',
                onPress: () {},
              ),
              BlocBuilder<TicketsCubit, TicketsState>(
                builder: (context, state) {
                  if (state is GetTicketsLoading) {
                    return const Center(child: CircularProgressIndicator(
                      color: AppColors.green,
                    ));
                  }
                  if (state is GetTicketsSuccess) {
                    return CustomOverviewWidget(
                      screenHeight: screenWidth,
                      screenWidth: screenWidth,
                      totalTickets: state.tickets.length,
                      doneTickets: state.tickets.where((ticket) => ticket.status == 'Completed').length,
                      awaitTickets: state.tickets.where((ticket) => ticket.status == 'Awaiting').length,
                    );
                  }
                  return CustomOverviewWidget(
                    screenHeight: screenWidth,
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
        SliverToBoxAdapter(child: SizedBox(height: 190)),

        SliverToBoxAdapter(
          // fillOverscroll: true,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            color: AppColors.white,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tickets Overview".tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ],
                  ),
                  BlocBuilder<TicketsCubit, TicketsState>(
                    builder: (context, state) {
                      if (state is GetTicketsLoading) {
                        return const Center(child: CircularProgressIndicator(
                          color: AppColors.green,
                        ));
                      }
                      if (state is GetTicketsFailure) {
                        return Center(child: Text(state.errMsg));
                      }
                      if (state is GetTicketsSuccess) {
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.tickets.length,
                          itemBuilder: (context, index) {
                            return Container(
                                margin: EdgeInsets.only(
                                    bottom: screenHeight * 0.05),
                                child: TicketOverViewWidget(
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    ticketData: state.tickets[index]
                                ));
                          },
                        );
                      }
                      return const Center(child: Text("No Tickets Found"));
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
