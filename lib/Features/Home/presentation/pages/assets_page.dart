

import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../widgets/assets_page_body.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {



  @override
  Widget build(BuildContext context) {

    return Scaffold(backgroundColor: AppColors.AppBackground,body: AssetsPageBody()) ;
  }
}
