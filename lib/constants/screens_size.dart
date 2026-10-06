import 'package:flutter/cupertino.dart';

class ScreensSize {
  final BuildContext context;

  ScreensSize(this.context);
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
}
