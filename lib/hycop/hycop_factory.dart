import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/util/config.dart';
//import '../common/util/logger.dart';
import 'account/abs_account.dart';
import 'account/account_manager.dart';
import 'account/appwrite_account.dart';
import 'account/firebase_account.dart';
import 'account/supabase_account.dart';
import 'database/abs_database.dart';
import 'database/appwrite_database.dart';
import 'database/firebase_database.dart';
import 'database/supabase_database.dart';
import 'function/abs_function.dart';
import 'function/appwrite_function.dart';
import 'function/firebase_function.dart';
import 'realtime/abs_realtime.dart';
import 'realtime/appwrite_realtime.dart';
import 'realtime/firebase_realtime.dart';
import 'realtime/supabase_realtime.dart';
import 'storage/abs_storage.dart';
import 'storage/appwrite_storage.dart';
import 'storage/firebase_storage.dart';
import 'function/supabase_function.dart';
import 'storage/supabase_storage.dart';

class HycopFactory {
  static String enterprise = 'Demo';
  static ServerType serverType = ServerType.firebase;

  static AbsDatabase? dataBase;
  static Future<void> selectDatabase() async {
    if (HycopFactory.serverType == ServerType.appwrite) {
      dataBase = AppwriteDatabase();
    } else if (HycopFactory.serverType == ServerType.supabase) {
      dataBase = SupabaseDatabase();
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
    } else if (HycopFactory.serverType == ServerType.supabase) {
      realtime = SupabaseRealtime();
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
    } else if (HycopFactory.serverType == ServerType.supabase) {
      function = SupabaseFunction();
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
    } else if (HycopFactory.serverType == ServerType.supabase) {
      storage = SupabaseAppStorage();
    } else {
      storage = FirebaseAppStorage();
    }
    await storage!.initialize();
    return;
  }

  static void setBucketId() {
    if ((AccountManager.currentLoginUser.isLoginedUser ||
            AccountManager.currentLoginUser.isGuestUser) &&
        HycopFactory.storage != null) {
      storage!.setBucket();
    }
  }

  static AbsAccount? account;
  static Future<void> selectAccount() async {
    if (HycopFactory.serverType == ServerType.appwrite) {
      account = AppwriteAccount();
    } else if (HycopFactory.serverType == ServerType.supabase) {
      account = SupabaseAccount();
    } else {
      account = FirebaseAccount();
    }
  }

  static Future<bool> initAll({bool force = false}) async {
    if (myConfig != null && force == false) return true;
    myConfig = HycopConfig(HycopFactory.enterprise, HycopFactory.serverType);
    await myConfig!.serverConfig.loadAsset();
    if (HycopFactory.serverType == ServerType.supabase) {
      final projectURL = myConfig!.serverConfig.dbConnInfo.databaseURL;
      // ignore: unused_local_variable
      final projectApiKey = myConfig!.serverConfig.dbConnInfo.apiKey;
      final projectServiceRoleKey = myConfig!.serverConfig.dbConnInfo.appId;
      await Supabase.initialize(
        url: projectURL,
        anonKey: projectServiceRoleKey,
      );
    }
    await HycopFactory.selectAccount();
    await AccountManager.getSession();
    //await myConfig!.load
    await HycopFactory.selectDatabase();
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
