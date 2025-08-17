import 'package:flutter/material.dart';

class SizeHelper {
  static double byWidth(BuildContext context, double designWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / 393) * designWidth;
  }

  static double byHeight(BuildContext context, double designHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight / 852) * designHeight;
  }
}
