import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../controller/assets_cubit.dart';

class AssetsSearchWidget extends StatelessWidget {
  const AssetsSearchWidget({super.key, required this.search});

  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      child: Column(
        spacing: 40,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomInputWidget(
              onChanged: (search) {
                return context.read<AssetsCubit>().searchAssets(search);
              },
              inbutIcon: 'assets/images/search.svg',
              inbutHintText: 'Search'.tr,
              changeToPass: false,
              textEditingController: search,
            ),
          ),

          SizedBox(height: 1),
        ],
      ),
    );
  }
}
