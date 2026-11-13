import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'package:efs_misr/Features/Assets_data/presentation/screens/add_assets_page.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_page_details_body.dart';
import 'package:efs_misr/core/auth/permissions_context.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AssetsDetailsPage extends StatefulWidget {
  const AssetsDetailsPage({super.key, required this.assets});
  final AssetsEntity assets;

  @override
  State<AssetsDetailsPage> createState() => _AssetsDetailsPageState();
}

class _AssetsDetailsPageState extends State<AssetsDetailsPage> {
  late AssetsEntity _asset = widget.assets;
  bool _busy = false;

  Future<void> _edit() async {
    final updated = await Get.to<AssetsEntity>(
      () => AddAssetsPage(asset: _asset),
    );
    if (updated == null || !mounted) return;
    setState(() => _asset = updated);
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      'Asset updated successfully'.tr,
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete asset?'.tr),
        content: Text(
          'Assets with tickets or repairs cannot be deleted. This cannot be undone.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AssetsCubit>().deleteAsset(_asset.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) {
        Get.back();
        showAppSnackBar(messenger, 'Asset deleted'.tr);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = context.permissions;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(color: Theme.of(context).colorScheme.primary),
        title: Text(
          'Assets Details'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
        actions: [
          if (permissions.canEditAsset)
            IconButton(
              tooltip: 'Edit'.tr,
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined, color: AppColors.green),
            ),
          if (permissions.canDeleteAsset)
            IconButton(
              tooltip: 'Delete'.tr,
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: AssetsDetailsPageBody(key: ValueKey(_asset), assets: _asset),
    );
  }
}
