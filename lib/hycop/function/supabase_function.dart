// ignore_for_file: depend_on_referenced_packages

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../hycop_factory.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
import '../database/abs_database.dart';
import 'abs_function.dart';

class SupabaseFunction extends AbsFunction {
  SupabaseFunction? function;

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

    if (function == null) {
      function = SupabaseFunction();
      function!.initialize();
    }

    assert(AbsDatabase.sbDBConn != null);
  }

  @override
  Future<String> execute({required String functionId, String? params, bool isAsync = false}) async {
    await initialize();
    String connectionStr = '"projectId":"${myConfig!.serverConfig!.dbConnInfo.projectId}",';
    connectionStr += '"databaseId":"${myConfig!.serverConfig!.dbConnInfo.appId}",';
    connectionStr += '"endPoint":"${myConfig!.serverConfig!.dbConnInfo.databaseURL}",';
    connectionStr += '"apiKey":"${myConfig!.serverConfig!.dbConnInfo.apiKey}"';
    String realParams = '';
    if (params == null) {
      realParams = '{$connectionStr}';
    } else {
      if (0 == params.indexOf("{")) {
        realParams = '{$connectionStr,${params.substring(1)}';
      } else {
        throw const HycopException(message: "params should start with '{'");
      }
    }
    logger.info('$functionId executed with $realParams');

    final result = await function!.execute(functionId: functionId, params: realParams);
    logger.info('$functionId finished, $result');

    return result;
  }
}
