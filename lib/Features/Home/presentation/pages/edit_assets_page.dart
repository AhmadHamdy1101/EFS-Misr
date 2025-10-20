import 'package:efs_misr/Features/Home/data/models/assets.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/add_accounts_page_body.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/edit_assets_page_body.dart';
import 'package:flutter/material.dart';

import '../widgets/add_assets_page_body.dart';

class EditAssetsPage extends StatelessWidget {
  const EditAssetsPage({super.key, this.assets});
  final Assets? assets;

  @override
  Widget build(BuildContext context) {
    return EditAssetsPageBody(assets: assets,);
  }
}