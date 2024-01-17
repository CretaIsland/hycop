import 'package:hycop/hycop/account/account_manager.dart';

import '../../hycop/storage/abs_storage.dart';
import '../../hycop/storage/appwrite_storage.dart';
import '../../hycop/storage/firebase_storage.dart';

//import '../common/util/logger.dart';
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
  static Future<void> selectDatabase() async {
    if (HycopFactory.serverType == ServerType.appwrite) {
      dataBase = AppwriteDatabase();
    } else {
      dataBase = FirebaseDatabase();
    }
    await dataBase!.initialize();
    return;
  }

  static AbsRealtime? realtime;
  static Future<void> selectRealTime() async {
    if (HycopFactory.serverType == ServerType.appwrite) {
      realtime = AppwriteRealtime();
    } else {
      realtime = FirebaseRealtime();
    }
    await realtime!.initialize();
    return;
  }

  static AbsFunction? function;
  static Future<void> selectFunction() async {
    if (HycopFactory.serverType == ServerType.appwrite) {
      function = AppwriteFunction();
    } else {
      function = FirebaseFunction();
    }
    await function!.initialize();
    return;
  }

  static AbsStorage? storage;
  static Future<void> selectStorage() async {
    if (HycopFactory.serverType == ServerType.appwrite) {
      storage = AppwriteStorage();
    } else {
      storage = FirebaseAppStorage();
    }
    await storage!.initialize();
    return;
  }

  static void setBucketId() {
    if ((AccountManager.currentLoginUser.isLoginedUser || AccountManager.currentLoginUser.isGuestUser) && HycopFactory.storage != null) {
      storage!.setBucket();
    }
  }

  static AbsAccount? account; // = null;
  static Future<void> selectAccount() async {
    //if (account != null) return;
    if (HycopFactory.serverType == ServerType.appwrite) {
      account = AppwriteAccount();
    } else {
      account = FirebaseAccount();
    }
  }

  static Future<bool> initAll({bool force = false}) async {
    if (myConfig != null && force == false) return true;
    myConfig = HycopConfig();
    await myConfig!.serverConfig!.loadAsset();
    await AccountManager.getSession();
    //await myConfig!.load
    await HycopFactory.selectDatabase();
    await HycopFactory.selectAccount();
    await AccountManager.getCurrentUserInfo();
    await HycopFactory.selectRealTime();
    await HycopFactory.selectFunction();
    await HycopFactory.selectStorage();
    HycopFactory.setBucketId();

    return true;
  }

  static String toServerTypeString() {
    String temp = '${HycopFactory.serverType}';
    return temp.substring("ServerType.".length);
  }
}
