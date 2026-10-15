import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/lookups/lookup_repo.dart';
import 'package:efs_misr/core/utils/singelton.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_button_widget.dart';
import '../../../../core/utils/widgets/custom_dropdown_widget.dart';
import '../controller/assets_cubit.dart';

/// Bottom sheet with its own state, so picking a value rebuilds the sheet
/// (not the page underneath) and each dropdown keeps its own selection.
class AssetsFilterSheet extends StatefulWidget {
  const AssetsFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AssetsCubit>(),
        child: const AssetsFilterSheet(),
      ),
    );
  }

  @override
  State<AssetsFilterSheet> createState() => _AssetsFilterSheetState();
}

class _AssetsFilterSheetState extends State<AssetsFilterSheet> {
  List<Map<String, dynamic>>? _areas;
  List<Map<String, dynamic>>? _branches;
  String? _area;
  String? _branch;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AssetsCubit>();
    _area = cubit.selectedAreaId?.toString();
    _branch = cubit.selectedBranchId?.toString();
    _load();
  }

  Future<void> _load() async {
    final lookups = getIt.get<LookupRepo>();
    final results = await Future.wait([
      lookups.getAreas(),
      lookups.getBranches(),
    ]);
    if (!mounted) return;
    setState(() {
      _areas = results[0].fold((_) => const [], (o) => o.toDropdownData());
      _branches = results[1].fold((_) => const [], (o) => o.toDropdownData());
      if (!_contains(_areas!, _area)) _area = null;
      if (!_contains(_branches!, _branch)) _branch = null;
    });
  }

  static bool _contains(List<Map<String, dynamic>> items, String? value) =>
      value != null && items.any((item) => item['value'] == value);

  void _apply({required bool clear}) {
    context.read<AssetsCubit>().filterAssets(
      area: clear ? null : int.tryParse(_area ?? ''),
      branch: clear ? null : int.tryParse(_branch ?? ''),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreensSize(context).screenWidth;
    final areas = _areas;
    final branches = _branches;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Text(
            'Filter'.tr,
            style: AppTextStyle.latoBold26(
              context,
            ).copyWith(color: AppColors.green),
          ),
          if (areas == null || branches == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.green),
            )
          else ...[
            _label(context, 'Area'),
            CustomDropdownWidget(
              inbutIcon: AppImages.images.address.path,
              inbutHintText: 'Area'.tr,
              selectedValue: _area,
              data: areas,
              onChanged: (value) => setState(() => _area = value),
            ),
            _label(context, 'Branch'),
            CustomDropdownWidget(
              inbutIcon: AppImages.images.address.path,
              inbutHintText: 'Branch'.tr,
              selectedValue: _branch,
              data: branches,
              onChanged: (value) => setState(() => _branch = value),
            ),
          ],
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: width * 0.4,
                child: CustomButtonWidget(
                  screenWidth: width,
                  toppadding: 10,
                  textstyle: AppTextStyle.latoBold26(context),
                  text: 'Filter'.tr,
                  color: AppColors.green,
                  foregroundcolor: Theme.of(context).primaryColor,
                  onpressed: () => _apply(clear: false),
                ),
              ),
              SizedBox(
                width: width * 0.4,
                child: CustomOutlineButtonWidget(
                  screenWidth: width,
                  borderColor: AppColors.green,
                  topPadding: 10,
                  foregroundColor: AppColors.green,
                  text: 'Clear'.tr,
                  textStyle: AppTextStyle.latoBold26(context),
                  onPressed: () => _apply(clear: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(text.tr, style: AppTextStyle.latoBold20(context)),
  );
}
