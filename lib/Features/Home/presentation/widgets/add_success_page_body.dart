import 'package:efs_misr/Features/Home/presentation/viewmodel/accounts_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/utils/app_text_styles.dart';

class AddSuccessPageBody extends StatefulWidget {
  const AddSuccessPageBody({
    super.key,
    required this.message,
    required this.buttonTitle,
    required this.onPress,
    this.secondPress,
  });

  final String message;
  final String buttonTitle;
  final onPress;

  final secondPress;

  @override
  State<AddSuccessPageBody> createState() => _AddSuccessPageBodyState();
}

class _AddSuccessPageBodyState extends State<AddSuccessPageBody> {
  @override
  void initState() {
    super.initState();
    context.read<AccountsCubit>().getAccounts();
  }

  // design here
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SizedBox(
        height: screenHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              SvgPicture.asset('assets/images/submited.svg'),
              Text('Add Successful', style: AppTextStyle.latoBold26(context)),
              Text(widget.message, style: AppTextStyle.latoBold26(context)),
              SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.green, AppColors.lightGreen],
                          begin: Alignment.topLeft, // نقطة البداية
                          end: Alignment.bottomRight, // نقطة النهاية
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onPress,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                          elevation: MaterialStateProperty.all<double>(0),
                        ),
                        child: Text(
                          widget.buttonTitle,
                          style: AppTextStyle.latoBold20(
                            context,
                          ).copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CustomOutlineButtonWidget(
                screenWidth: screenWidth,
                borderColor: AppColors.green,
                topPadding: 10,
                color: Colors.transparent,
                foregroundColor: AppColors.green,
                onPressed: widget.secondPress,
                text: 'Back',
                textStyle: AppTextStyle.latoBold20(context),
              ),
              // ElevatedButton(
              //   onPressed: secondPress,
              //   style: ButtonStyle(
              //     backgroundColor: WidgetStateProperty.all<Color>(
              //       Colors.transparent,
              //     ),
              //     elevation: WidgetStateProperty.all<double>(0),
              //   ),
              //   child: Text(
              //     'Back',
              //     style: AppTextStyle.latoBold20(
              //       context,
              //     ).copyWith(color: AppColors.white),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
