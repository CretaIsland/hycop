// ignore_for_file: depend_on_referenced_packages

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'logger.dart';

class DeviceInfo {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  static Map<String, dynamic> deviceData = <String, dynamic>{};

  static String deviceId = const Uuid().v4();

  static Future<void> init() async {
    deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);

    logger.finest("browserName=${deviceData['browserName']}");
    logger.finest("appCodeName=${deviceData['appCodeName']}");
    logger.finest("appName=${deviceData['appName']}");
    logger.finest("appVersion=${deviceData['appVersion']}");
    logger.finest("deviceMemory=${deviceData['deviceMemory']}");
    logger.finest("language=${deviceData['language']}");
    logger.finest("languages=${deviceData['languages']}");
    logger.finest("platform=${deviceData['platform']}");
    logger.finest("product=${deviceData['product']}");
    logger.finest("productSub=${deviceData['productSub']}");
    logger.finest("userAgent=${deviceData['userAgent']}");
    logger.finest("vendor=${deviceData['vendor']}");
    logger.finest("vendorSub=${deviceData['vendorSub']}");
    logger.finest("hardwareConcurrency=${deviceData['hardwareConcurrency']}");
    logger.finest("maxTouchPoints=${deviceData['maxTouchPoints']}");
  }

  static Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic>{
      'browserName': describeEnum(data.browserName),
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory,
      'language': data.language,
      'languages': data.languages,
      'platform': data.platform,
      'product': data.product,
      'productSub': data.productSub,
      'userAgent': data.userAgent,
      'vendor': data.vendor,
      'vendorSub': data.vendorSub,
      'hardwareConcurrency': data.hardwareConcurrency,
      'maxTouchPoints': data.maxTouchPoints,
    };
  }
}
