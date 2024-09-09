// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../../hycop/utils/hycop_exceptions.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
import '../database/abs_database.dart';
import 'abs_function.dart';

class SupabaseFunction extends AbsFunction {
  @override
  Future<void> initialize() async {
    if (AbsDatabase.sbDBConn == null) {
      // await HycopFactory.initAll();
      logger.finest('initialize');
      // await Supabase.initialize(
      //   url: myConfig!.serverConfig.dbConnInfo.databaseURL,
      //   anonKey: myConfig!.serverConfig.dbConnInfo.apiKey,
      // );
      AbsDatabase.setSupabaseApp(Supabase.instance.client);

      //AbsDatabase.sbDBConn = null;
    }
    assert(AbsDatabase.sbDBConn != null);
  }

  @override
  Future<String> execute({required String functionId, String? params, bool isAsync = false}) async {
    return Future.value('');
  }

  @override
  Future<String> execute2(
      {required String functionId, Map<String, dynamic>? params, bool isAsync = true}) async {
    //print('execute2 $functionId');

    await initialize();

    Map<String, dynamic> realParams = {};

    //realParams["projectId"] = myConfig!.serverConfig.dbConnInfo.projectId;
    //realParams["databaseId"] = myConfig!.serverConfig.dbConnInfo.appId;
    realParams["endPoint"] = myConfig!.serverConfig.dbConnInfo.databaseURL;
    realParams["apiKey"] = myConfig!.serverConfig.dbConnInfo.apiKey;
    realParams["roleKey"] = myConfig!.serverConfig.dbConnInfo.appId;

    if (params != null) {
      realParams.addAll(params);
    }
    String body = jsonEncode(realParams);
    final result = await Supabase.instance.client.functions
        .invoke(functionId, body: body, queryParameters: realParams);
    logger.info('$functionId finished, $result');

    return result.toString();
  }
}
