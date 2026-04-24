import 'dart:math';
import 'package:flutter/material.dart';

class LayoutUtil {
  static double getScale(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortSide = min(size.width, size.height);

    // Base design was for ~375 width (iPhone 13 mini)
    if (shortSide >= 600) return 1.4; // Tablet
    if (shortSide >= 400) return 1.1; // Large Phone
    return 1.0; // Standard Phone
  }

  static double fontSize(BuildContext context, double base) {
    final userScale = MediaQuery.textScalerOf(context).scale(1.0);
    return base * getScale(context) * userScale;
  }

  static double spacing(BuildContext context, double base) {
    return base * getScale(context);
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }
}
