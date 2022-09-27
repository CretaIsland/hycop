// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';

import '../../hycop/hycop_factory.dart';
import 'logger.dart';

enum ServerType {
  none,
  firebase,
  appwrite;

  static ServerType fromString(String arg) {
    if (arg == 'firebase') return ServerType.firebase;
    if (arg == 'appwrite') return ServerType.appwrite;
    return ServerType.none;
  }
}

class DBConnInfo {
  String apiKey = "";
  String authDomain = "";
  String databaseURL = ''; // appwrite endpoint
  String projectId = ""; // appwrite projectId
  String storageBucket = "";
  String messagingSenderId = "";
  String appId = ""; // appwrite databaseId
}

class StorageConnInfo {
  String apiKey = "";
  String appId = "";
  String storageURL = ""; // appwrite endpoint
  String projectId = ""; // appwrite projectId
  String bucketId = ""; // appwrite storage bucketId, firebase user folder path
  String messagingSenderId = "";
}

class SocketConnInfo {
  String serverUrl = "";
  String serverPort = "";
  String roomId = '';
}

abstract class AbsServerConfig {
  final String enterprise;

  DBConnInfo dbConnInfo = DBConnInfo();
  //DBConnInfo rtConnInfo = DBConnInfo();
  StorageConnInfo storageConnInfo = StorageConnInfo();
  SocketConnInfo socketConnInfo = SocketConnInfo();

  // String apiKey = "";
  // String authDomain = "";
  // String databaseURL = ''; // appwrite endpoint
  // String projectId = ""; // appwrite projectId
  // String storageBucket = "";
  // String messagingSenderId = "";
  // String appId = ""; // appwrite databaseId

  AbsServerConfig(this.enterprise);
}

class FirebaseConfig extends AbsServerConfig {
  FirebaseConfig({String enterprise = 'creta'}) : super(enterprise) {
    if (enterprise == 'creta') {
      // database info
      // dbConnInfo.apiKey = "AIzaSyBe_K6-NX9-lzYNjQCPOFWbaOUubXqWVHg";
      // dbConnInfo.authDomain = "creta01-ef955.firebaseapp.com";
      // dbConnInfo.databaseURL = ''; // 일반 Database 에는 이상하게 이 값이 없다.
      // dbConnInfo.projectId = "creta01-ef955";
      // dbConnInfo.storageBucket = "creta01-ef955.appspot.com";
      // dbConnInfo.messagingSenderId = "878607742856";
      // dbConnInfo.appId = "1:878607742856:web:87e91c3185d1a79980ec3d";

      // // realTime info
      // rtConnInfo.apiKey = "AIzaSyCq3Ap2QXjMfPptFyHLHNCyVTeQl9G2PoY";
      // rtConnInfo.authDomain = "creta02-1a520.firebaseapp.com";
      // rtConnInfo.databaseURL = "https://creta02-1a520-default-rtdb.firebaseio.com";
      // rtConnInfo.projectId = "creta02-1a520";
      // rtConnInfo.storageBucket = "creta02-1a520.appspot.com";
      // rtConnInfo.messagingSenderId = "352118964959";
      // rtConnInfo.appId = "1:352118964959:web:6b9d9378aad1b7c9261f6a";
      dbConnInfo.apiKey = "AIzaSyCq3Ap2QXjMfPptFyHLHNCyVTeQl9G2PoY";
      dbConnInfo.authDomain = "creta02-1a520.firebaseapp.com";
      dbConnInfo.databaseURL = "https://creta02-1a520-default-rtdb.firebaseio.com";
      dbConnInfo.projectId = "creta02-1a520";
      dbConnInfo.storageBucket = "creta02-1a520.appspot.com";
      dbConnInfo.messagingSenderId = "352118964959";
      dbConnInfo.appId = "1:352118964959:web:6b9d9378aad1b7c9261f6a";

      storageConnInfo.apiKey = "AIzaSyCOmmEEjgWjgqcl2GFfsD4KP2G_WiThVn4";
      storageConnInfo.appId = "1:93171668117:web:e0105cd1713392cf64f79c";
      storageConnInfo.projectId = "creta-dev";
      storageConnInfo.storageURL = "creta-dev.appspot.com";
      storageConnInfo.messagingSenderId = "93171668117";

      socketConnInfo.serverUrl = "ws://127.0.0.1";
      socketConnInfo.serverPort = "4432";
    }
    if (enterprise == 'Demo') {
      // database info
      // dbConnInfo.apiKey = "AIzaSyBe_K6-NX9-lzYNjQCPOFWbaOUubXqWVHg";
      // dbConnInfo.authDomain = "creta01-ef955.firebaseapp.com";
      // dbConnInfo.databaseURL = ''; // 일반 Database 에는 이상하게 이 값이 없다.
      // dbConnInfo.projectId = "creta01-ef955";
      // dbConnInfo.storageBucket = "creta01-ef955.appspot.com";
      // dbConnInfo.messagingSenderId = "878607742856";
      // dbConnInfo.appId = "1:878607742856:web:87e91c3185d1a79980ec3d";

      // realTime info
      // rtConnInfo.apiKey = "AIzaSyCq3Ap2QXjMfPptFyHLHNCyVTeQl9G2PoY";
      // rtConnInfo.authDomain = "creta02-1a520.firebaseapp.com";
      // rtConnInfo.databaseURL = "https://creta02-1a520-default-rtdb.firebaseio.com";
      // rtConnInfo.projectId = "creta02-1a520";
      // rtConnInfo.storageBucket = "creta02-1a520.appspot.com";
      // rtConnInfo.messagingSenderId = "352118964959";
      // rtConnInfo.appId = "1:352118964959:web:6b9d9378aad1b7c9261f6a";

      dbConnInfo.apiKey = "AIzaSyCq3Ap2QXjMfPptFyHLHNCyVTeQl9G2PoY";
      dbConnInfo.authDomain = "creta02-1a520.firebaseapp.com";
      dbConnInfo.databaseURL = "https://creta02-1a520-default-rtdb.firebaseio.com";
      dbConnInfo.projectId = "creta02-1a520";
      dbConnInfo.storageBucket = "creta02-1a520.appspot.com";
      dbConnInfo.messagingSenderId = "352118964959";
      dbConnInfo.appId = "1:352118964959:web:6b9d9378aad1b7c9261f6a";

      storageConnInfo.apiKey = "AIzaSyCOmmEEjgWjgqcl2GFfsD4KP2G_WiThVn4";
      storageConnInfo.appId = "1:93171668117:web:e0105cd1713392cf64f79c";
      storageConnInfo.projectId = "creta-dev";
      storageConnInfo.storageURL = "creta-dev.appspot.com";
      storageConnInfo.messagingSenderId = "93171668117";

      socketConnInfo.serverUrl = "ws://127.0.0.1";
      socketConnInfo.serverPort = "4432";
    }
  }
}

class AppwriteConfig extends AbsServerConfig {
  AppwriteConfig({String enterprise = 'creta'}) : super(enterprise) {
    if (enterprise == 'creta') {
      dbConnInfo.apiKey =
          "163c3964999075adc6b7317f211855832ebb6d464520446280af0f8bbb9e642ffdcd2588a5141ce3ea0011c5780ce10986ed57b742fdb6a641e2ecf7310512cd5349e61385f856eb4789e718d750e2451c1b1519dd20cdf557b5edc1ae066e28430f5cc3e157abc4a13ad6aa112a48b07ce707341edfdc41d2572e95b4728905"; // apiKet
      dbConnInfo.databaseURL = "http://192.168.10.3/v1"; // endPoint
      dbConnInfo.projectId = "62d79f0b36f4029ce40f";
      dbConnInfo.appId = "62d79f2e5fda513f4807"; // databaseId

      storageConnInfo.storageURL = "http://localhost:3307/v1";
      storageConnInfo.projectId = "62fee22718a67d077012";
      storageConnInfo.apiKey =
          "2b99b89f2ad015511fa3a8787806993d535e26e739876e002aaf29280b5b844174a9a4d545f90f91fa8047553a035df68461b4eda951c8a225feccd7641049dee230c2d16917da57bc74ac9de1965663f0db1885b2a5e7d586b5e423c26c63f70eb21c5bb5bb87f215d3e52aaa243e0222fdf2f6613764875aa42c0d5eadb464";

      socketConnInfo.serverUrl = "ws://127.0.0.1";
      socketConnInfo.serverPort = "4432";
    }
    if (enterprise == 'Demo') {
      dbConnInfo.apiKey =
          "a3d5ba69e4972a10ee68903c2a91f0fe349754849831613d5505d9ddfa1cb87ac9031588975ea6eca28c5afbceba18bc762f824dd0fdbe12c0b8c6c2b7fe61fd5ab8b8cac2d365f6c805116dafc06cd37e1a7e2cd03a898662ca20db7640b606eb7cd0ae806d433531b997a1d48babac24800fa8b0a1b93b81df6c68db8f01b8"; // apiKet
      dbConnInfo.databaseURL =
          "http://ec2-3-37-163-220.ap-northeast-2.compute.amazonaws.com:9090/v1"; // endPoint
      dbConnInfo.projectId = "hycopTest";
      dbConnInfo.appId = "hycopTestDB"; // databaseId

      storageConnInfo.storageURL =
          "http://ec2-3-37-163-220.ap-northeast-2.compute.amazonaws.com:9090/v1";
      storageConnInfo.projectId = "hycopTest";
      storageConnInfo.apiKey =
          "a3d5ba69e4972a10ee68903c2a91f0fe349754849831613d5505d9ddfa1cb87ac9031588975ea6eca28c5afbceba18bc762f824dd0fdbe12c0b8c6c2b7fe61fd5ab8b8cac2d365f6c805116dafc06cd37e1a7e2cd03a898662ca20db7640b606eb7cd0ae806d433531b997a1d48babac24800fa8b0a1b93b81df6c68db8f01b8";

      socketConnInfo.serverUrl = "ws://127.0.0.1";
      socketConnInfo.serverPort = "4432";
    }
  }
}

class AssetConfig {
  final String enterprise;
  AssetConfig({this.enterprise = 'creta'});

  int savePeriod = 1000;
  Future<void> loadAsset(BuildContext context) async {
    String jsonString = '';
    try {
      jsonString =
          await DefaultAssetBundle.of(context).loadString('assets/${enterprise}_config.json');
    } catch (e) {
      logger.info('assets/${enterprise}_config.json not exist, creta_config.json will be used');
      try {
        jsonString = await DefaultAssetBundle.of(context).loadString('assets/creta_config.json');
      } catch (e) {
        logger.severe('load assets/${enterprise}_config.json failed', e);
        return;
      }
    }
    final dynamic jsonMap = jsonDecode(jsonString);
    savePeriod = jsonMap['savePeriod'] ?? 1000;
  }
}

HycopConfig? myConfig;

class HycopConfig {
  //final String enterprise;
  //final ServerType serverType;
  late AssetConfig config;
  AbsServerConfig? serverConfig;

  //HycopConfig({required this.enterprise, required this.serverType}) {
  HycopConfig() {
    config = AssetConfig(enterprise: HycopFactory.enterprise);
    if (HycopFactory.serverType == ServerType.firebase) {
      serverConfig = FirebaseConfig(enterprise: HycopFactory.enterprise);
    } else if (HycopFactory.serverType == ServerType.appwrite) {
      serverConfig = AppwriteConfig(enterprise: HycopFactory.enterprise);
    }
  }
}
