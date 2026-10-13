import 'package:efs_misr/Features/Tickets/domain/entities/ticket_lookup_option.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';
import 'ticket_dropdown_field.dart';

class TicketFilterSheet extends StatefulWidget {
  const TicketFilterSheet({super.key});

  @override
  State<TicketFilterSheet> createState() => _TicketFilterSheetState();
}

class _TicketFilterSheetState extends State<TicketFilterSheet> {
  late int? _areaId;
  late int? _branchId;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<TicketsCubit>();
    _areaId = cubit.selectedAreaId;
    _branchId = cubit.selectedBranchId;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();
    final areas = cubit.areaOptions;
    final branches = _branchesForArea(cubit, _areaId);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.green),
            ),
            const SizedBox(height: 20),
            TicketDropdownField(
              label: 'Area',
              options: areas,
              value: _areaId,
              onChanged: (value) => setState(() {
                _areaId = value;
                if (!_branchesForArea(
                  cubit,
                  value,
                ).any((branch) => branch.id == _branchId)) {
                  _branchId = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            TicketDropdownField(
              label: 'Branch',
              options: branches,
              value: _branchId,
              onChanged: (value) => setState(() => _branchId = value),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.green),
                  onPressed: () {
                    cubit.filterTickets();
                    Navigator.of(context).pop();
                  },
                  child: Text('Clear'.tr),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () {
                    cubit.filterTickets(area: _areaId, branch: _branchId);
                    Navigator.of(context).pop();
                  },
                  child: Text('Apply'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TicketLookupOption> _branchesForArea(TicketsCubit cubit, int? areaId) {
    return cubit.branchOptions
        .where((branch) {
          if (areaId == null) return true;
          return cubit.allTickets.any(
            (ticket) =>
                ticket.branchEntity?.id == branch.id &&
                ticket.branchEntity?.areaId == areaId,
          );
        })
        .toList(growable: false);
  }
}
