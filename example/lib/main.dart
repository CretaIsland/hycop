//library hycop;

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/hycop_example_app.dart';
import 'package:hycop/common/util/logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogger();
  //DeviceInfo.init();
  // myConfig = HycopConfig(enterprise: 'skpark', serverType: ServerType.firebase);
  // HycopFactory.selectDatabase();
  // HycopFactory.selectRealTime();
  // HycopFactory.selectFunction();

  const String testValue = String.fromEnvironment('USERNAME', defaultValue: 'unknown');
  logger.info("-------------------------------$testValue");

  runApp(const ProviderScope(child: HycopExampleApp()));
}
