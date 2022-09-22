import 'package:flutter/material.dart';

class CommonUtils {
  static String hideString(String org, {int max = 0}) {
    int len = org.length;
    if (len < 6) {
      return "*****";
    }
    if (max > 0 && len > max) {
      len = max;
    }
    int half = (len / 2).round();
    String postFix = '';
    for (int i = 0; i < half; i++) {
      postFix += '*';
    }
    return org.substring(0, half) + postFix;
  }

  static Color stringToColor(String? colorStr) {
    if (colorStr != null && colorStr.length > 16) {
      int pos = colorStr.indexOf('0x');
      String key = colorStr.substring(pos + 2, pos + 2 + 8);
      return Color(int.parse(key, radix: 16));
    }
    return Colors.transparent;
  }
}
