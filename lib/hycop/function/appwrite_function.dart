// ignore_for_file: depend_on_referenced_packages

import 'package:appwrite/appwrite.dart';
import '../../hycop/utils/hycop_exceptions.dart';
//import '../../hycop/hycop_factory.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
import '../database/abs_database.dart';
import 'abs_function.dart';

class AppwriteFunction extends AbsFunction {
  Functions? functions;

  @override
  Future<void> initialize() async {
    // ignore: prefer_conditional_assignment
    if (functions == null) {
      //await HycopFactory.initAll();
      functions = Functions(AbsDatabase.awDBConn!);
    }
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
    final result =
        await functions!.createExecution(functionId: functionId, data: realParams, xasync: false);
    logger.info('$functionId finished, ${result.statusCode}, ${result.response}');

    return result.response;
  }
}
