// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/routes.dart';
import 'package:routemaster/routemaster.dart';

class HycopExampleApp extends ConsumerStatefulWidget {
  const HycopExampleApp({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HycopExampleAppState();
}

class _HycopExampleAppState extends ConsumerState<HycopExampleApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Welcome to hycop world',
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.light().copyWith(
      //   scaffoldBackgroundColor: Colors.black,
      //   primaryColor: const Color.fromRGBO(21, 30, 61, 1),
      // ),
      routerDelegate: RoutemasterDelegate(routesBuilder: (context) {
        return routesLoggedOut;
      }),
      routeInformationParser: const RoutemasterParser(),
    );
  }
}
