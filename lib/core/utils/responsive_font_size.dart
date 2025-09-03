import 'package:flutter/material.dart';

import 'size_config.dart';

double getScaleFactor(BuildContext context) {
  double width = MediaQuery.sizeOf(context).width;
  if (width < SizeConfig.tablet) {
    return width / 550;
  } else if (width < SizeConfig.desktop) {
    return width / 850;
  } else {
    return width / 1850;
  }
}

double getResponsiveFontSize(BuildContext context, double fontSize) {
  double scaleFactor = getScaleFactor(context);
  double responseFont = fontSize * scaleFactor;

  double lowerLimit = fontSize * .8;
  double upperLimit = fontSize * 1.2;

  return responseFont.clamp(lowerLimit, upperLimit);
}
