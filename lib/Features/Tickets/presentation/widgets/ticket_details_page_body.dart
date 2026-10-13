import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/add_assets_to_tickets_dailog.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_asset_card.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_details_container.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TicketDetailsPageBody extends StatefulWidget {
  const TicketDetailsPageBody({super.key, required this.ticket});

  final TicketEntity ticket;

  @override
  State<TicketDetailsPageBody> createState() => _TicketDetailsPageBodyState();
}

class _TicketDetailsPageBodyState extends State<TicketDetailsPageBody> {
  final _damageCommentController = TextEditingController();
  final _repairCommentController = TextEditingController();
  final _amountController = TextEditingController();
  final _selectedRepairType = ''.obs;

  @override
  void initState() {
    super.initState();
    _damageCommentController.text = widget.ticket.damageDescription;
  }

  @override
  void dispose() {
    _damageCommentController.dispose();
    _repairCommentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _openRepairDialog(BuildContext context, AssetsEntity asset) {
    _repairCommentController.clear();
    _amountController.clear();
    _selectedRepairType.value = '';
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AddAssetsToTicketsDialog(
        comment: _repairCommentController,
        selectedValue: null,
        selectedRepairValue: _selectedRepairType,
        amount: _amountController,
        ticket: widget.ticket,
        asset: asset,
        scaffoldMessenger: messenger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TicketDetailsContainer(
            ticket: widget.ticket,
            damageComment: _damageCommentController,
          ),
        ),
        BlocBuilder<AssetsTicketsCubit, AssetsTicketsState>(
          builder: (context, state) {
            if (state is GetAssetsTicketsFailure) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(state.message)),
              );
            }
            if (state is GetAssetsTicketsLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
              );
            }
            if (state is GetAssetsTicketsSuccess) {
              final assets = state.assetsAndTickets;
              if (assets.isEmpty) return _emptyAssetsState(context);
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = assets[index];
                  return TicketAssetCard(
                    data: item,
                    onTap: () => _openRepairDialog(context, item.asset),
                  );
                }, childCount: assets.length),
              );
            }
            return _emptyAssetsState(context);
          },
        ),
      ],
    );
  }

  Widget _emptyAssetsState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          'No Assets Added Yet'.tr,
          style: AppTextStyle.latoBold23(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
    );
  }
}
