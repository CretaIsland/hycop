//library hycop;

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/hycop_example_app.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/hycop_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogger();
  //DeviceInfo.init();
  // myConfig = HycopConfig(enterprise: 'skpark', serverType: ServerType.firebase);
  // HycopFactory.selectDatabase();
  // HycopFactory.selectRealTime();
  // HycopFactory.selectFunction();

  await HycopFactory.initAll();

  const String testValue = String.fromEnvironment('USERNAME', defaultValue: 'unknown');
  logger.info("-------------------------------$testValue");

  runApp(const ProviderScope(child: HycopExampleApp()));
}
