// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
//import '../../hycop/hycop_factory.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../common/util/config.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../../common/util/logger.dart';
import 'abs_function.dart';

class FirebaseFunction extends AbsFunction {
  FirebaseFunctions? functions;
  @override
  Future<void> initialize() async {
    if (functions == null) {
      //await HycopFactory.initAll();
      FirebaseApp app = await Firebase.initializeApp(
          name: "functions",
          options: FirebaseOptions(
              apiKey: myConfig!.serverConfig!.dbConnInfo.apiKey,
              appId: myConfig!.serverConfig!.dbConnInfo.appId,
              storageBucket: myConfig!.serverConfig!.dbConnInfo.storageBucket,
              messagingSenderId: myConfig!.serverConfig!.dbConnInfo.messagingSenderId,
              projectId: myConfig!.serverConfig!.dbConnInfo.projectId));

      functions = FirebaseFunctions.instanceFor(app: app);
    }
  }

  @override
  Future<String> execute({required String functionId, String? params, bool isAsync = true}) async {
    await initialize();
    logger.finest('execute($functionId)');
    try {
      Map<String, dynamic>? jsonParams;
      if (params != null) {
        logger.finest('params=($params)');
        jsonParams = jsonDecode(params);
      }
      final HttpsCallableResult result =
          await functions!.httpsCallable(functionId).call(jsonParams);
      return result.data.toString();
    } on FirebaseFunctionsException catch (error) {
      logger.severe(error.code);
      logger.severe(error.details);
      logger.severe(error.message);
      throw HycopException(message: error.message!, code: int.parse(error.code));
    }
  }
}
