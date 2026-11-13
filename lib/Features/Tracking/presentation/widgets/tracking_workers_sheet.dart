import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/worker_location_model.dart';
import '../controller/tracking_cubit.dart';
import '../controller/tracking_state.dart';
import 'tracking_map_widget.dart';
import 'worker_row_tile.dart';

class TrackingWorkersSheet extends StatelessWidget {
  const TrackingWorkersSheet({
    super.key,
    required this.state,
    required this.scrollController,
    required this.isDarkMode,
    required this.onStyleSelected,
  });

  final TrackingState state;
  final ScrollController scrollController;
  final bool isDarkMode;
  final ValueChanged<MapStyleType> onStyleSelected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrackingCubit>();

    final shownWorkers = state.workers.where((worker) {
      final matchesFilter = state.filterTab == 'All' ||
          (state.filterTab == 'Live' && worker.status == WorkerStatus.live) ||
          (state.filterTab == 'Offline' &&
              worker.status == WorkerStatus.offline) ||
          (state.filterTab == 'Pending' &&
              worker.status == WorkerStatus.pending);
      final matchesQuery = worker.name
          .toLowerCase()
          .contains(state.searchQuery.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.buttondark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Workers'.tr,
                      style: AppTextStyle.latoBold16(context).copyWith(
                        color: isDarkMode ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        shownWorkers.length.toString(),
                        style: AppTextStyle.latoBold12(context).copyWith(
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<MapStyleType>(
                  icon: const Icon(Icons.layers_outlined, color: AppColors.green),
                  onSelected: onStyleSelected,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: MapStyleType.openStreetMap,
                        child: Text('Standard Map')),
                    const PopupMenuItem(
                        value: MapStyleType.satellite,
                        child: Text('Satellite Imagery')),
                    const PopupMenuItem(
                        value: MapStyleType.cartoLight,
                        child: Text('Carto Light')),
                    const PopupMenuItem(
                        value: MapStyleType.cartoDark,
                        child: Text('Carto Dark')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: cubit.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search workers...'.tr,
                prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                filled: true,
                fillColor:
                    isDarkMode ? AppColors.scafolddark : AppColors.appBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Live', 'Offline', 'Pending'].map((tab) {
                final isSelected = state.filterTab == tab;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => cubit.setFilterTab(tab),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.green
                              : (isDarkMode
                                  ? AppColors.scafolddark
                                  : AppColors.appBackground),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tab.tr,
                          style: AppTextStyle.latoBold12(context).copyWith(
                            color: isSelected
                                ? AppColors.white
                                : (isDarkMode
                                    ? AppColors.white
                                    : AppColors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shownWorkers.isEmpty
                ? SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'No workers found'.tr,
                        style: AppTextStyle.latoRegular16(context).copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shownWorkers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final worker = shownWorkers[index];
                      return WorkerRowTile(
                        worker: worker,
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
