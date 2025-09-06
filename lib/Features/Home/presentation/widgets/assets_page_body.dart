import 'package:efs_misr/Features/Home/presentation/pages/assets_details_page.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AssetsPageBody extends StatefulWidget {
  const AssetsPageBody({super.key});

  @override
  State<AssetsPageBody> createState() => _AssetsPageBodyState();
}

class _AssetsPageBodyState extends State<AssetsPageBody> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: SizedBox(),
        centerTitle: true,
        title: Text(
          'Assets',
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      backgroundColor: AppColors.AppBackground,
      body: BlocConsumer<AssetsCubit, AssetsState>(
        builder: (context, state) {
          if (state is GetAssetsLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.green,));
          }
          else if (state is GetAssetsSuccess) {
            final assets = state.assets;
            return ListView.builder(
              itemCount: state.assets.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.to(AssetsDetailsPage(assets: state.assets[index],));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: AppColors.white,
                    margin: const EdgeInsets.all(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: Row(
                        spacing: 15,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: AppColors.lightgreen.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: ClipRRect(
                              child: SvgPicture.asset(
                                'assets/images/Chair.svg',
                                color: AppColors.green,
                                width: screenWidth * 0.1,
                                height: screenWidth * 0.1,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [Text("AC:"), Text('${assets[index].id}')]),
                              Text(
                                'Branch name'.tr,
                                style: AppTextStyle.latoRegular16(
                                  context,
                                ).copyWith(color: AppColors.green),
                              ),
                              Text(
                                '${assets[index].branchObject?.name}'.tr,
                                style: AppTextStyle.latoRegular16(
                                  context,
                                ).copyWith(color: AppColors.gray),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              spacing: 10,
                              children: [
                                Text("Total Spend".tr),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xff8FCFAD),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    "1,000 EGP",
                                    style: AppTextStyle.latoBold16(
                                      context,
                                    ).copyWith(color: AppColors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          else if (state is GetAssetsFailure) {
            return Center(child: Text(state.errMsg));
          }
          else {
            return Center(child: Text('No Assets Found'));
          }

        }, listener: (BuildContext context, AssetsState state) {  },
      ),
    );
  }
}
