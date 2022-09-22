import '../../hycop/storage/abs_storage.dart';
import '../../hycop/storage/appwrite_storage.dart';
import '../../hycop/storage/firebase_storage.dart';

import '../common/util/logger.dart';
import 'database/firebase_database.dart';
import 'database/appwrite_database.dart';
import 'database/abs_database.dart';
import 'realtime/abs_realtime.dart';
import 'realtime/firebase_realtime.dart';
import 'realtime/appwrite_realtime.dart';
import 'function/abs_function.dart';
import 'function/appwrite_function.dart';
import 'function/firebase_function.dart';
import '../common/util/config.dart';
import 'account/abs_account.dart';
import 'account/appwrite_account.dart';
import 'account/firebase_account.dart';

class HycopFactory {
  static String enterprise = 'Demo';
  static ServerType serverType = ServerType.firebase;
  static AbsDatabase? dataBase;
  static void selectDatabase() {
    if (HycopFactory.serverType == ServerType.appwrite) {
      dataBase = AppwriteDatabase();
    } else {
      dataBase = FirebaseDatabase();
    }
    dataBase!.initialize();
    return;
  }

  static AbsRealtime? realtime;
  static void selectRealTime() {
    if (HycopFactory.serverType == ServerType.appwrite) {
      realtime = AppwriteRealtime();
    } else {
      realtime = FirebaseRealtime();
    }
    realtime!.initialize();
    return;
  }

  static AbsFunction? function;
  static void selectFunction() {
    if (HycopFactory.serverType == ServerType.appwrite) {
      function = AppwriteFunction();
    } else {
      function = FirebaseFunction();
    }
    function!.initialize();
    return;
  }

  static AbsStorage? storage;
  static void selectStorage() {
    if (HycopFactory.serverType == ServerType.appwrite) {
      storage = AppwriteStorage();
    } else {
      storage = FirebaseAppStorage();
    }
    storage!.initialize();
    return;
  }

  static AbsAccount? account; // = null;
  static void selectAccount() {
    if (account != null) return;
    if (HycopFactory.serverType == ServerType.appwrite) {
      account = AppwriteAccount();
    } else {
      account = FirebaseAccount();
    }
  }


  static void initAll() {
    if (myConfig != null) return;
    logger.info('initAll()');
    myConfig = HycopConfig();
    HycopFactory.selectDatabase();
    HycopFactory.selectRealTime();
    HycopFactory.selectFunction();
    HycopFactory.selectStorage();
    HycopFactory.selectAccount();
  }
}
