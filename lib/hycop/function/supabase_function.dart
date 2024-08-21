// ignore_for_file: depend_on_referenced_packages

import 'package:supabase_flutter/supabase_flutter.dart';
//import '../../hycop/utils/hycop_exceptions.dart';
import '../hycop_factory.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
import '../database/abs_database.dart';
import 'abs_function.dart';

class SupabaseFunction extends AbsFunction {
  @override
  Future<void> initialize() async {
    if (AbsDatabase.sbDBConn == null) {
      await HycopFactory.initAll();
      logger.finest('initialize');
      await Supabase.initialize(
        url: myConfig!.serverConfig!.dbConnInfo.databaseURL,
        anonKey: myConfig!.serverConfig!.dbConnInfo.apiKey,
      );
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
    await initialize();

    Map<String, dynamic> realParams = {};

    realParams["projectId"] = myConfig!.serverConfig!.dbConnInfo.projectId;
    realParams["databaseId"] = myConfig!.serverConfig!.dbConnInfo.appId;
    realParams["endPoint"] = myConfig!.serverConfig!.dbConnInfo.databaseURL;
    realParams["apiKey"] = myConfig!.serverConfig!.dbConnInfo.apiKey;

    if (params != null) {
      realParams.addAll(params);
    }
    final result =
        await Supabase.instance.client.functions.invoke(functionId, queryParameters: realParams);
    logger.info('$functionId finished, $result');

    return result.toString();
  }
}
