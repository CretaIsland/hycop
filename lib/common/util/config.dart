// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
//import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../hycop/hycop_factory.dart';
import 'my_encrypt.dart';
import 'logger.dart';

enum ServerType {
  none,
  firebase,
  appwrite,
  supabase;

  static ServerType fromString(String arg) {
    if (arg == 'firebase') return ServerType.firebase;
    if (arg == 'appwrite') return ServerType.appwrite;
    if (arg == 'supabase') return ServerType.supabase;
    return ServerType.none;
  }
}

class DBConnInfo {
  String apiKey = ""; //supabase projectKey
  String authDomain = "";
  String databaseURL = ''; // appwrite endpoint    //supabase projectUrl
  String projectId = ""; // appwrite projectId,
  String storageBucket = "";
  String messagingSenderId = "";
  String appId = ""; // appwrite databaseId

  void fromJson(Map<String, dynamic> json) {
    apiKey = json['apiKey'] ?? '';
    authDomain = json['authDomain'] ?? '';
    databaseURL = json['databaseURL'] ?? '';
    projectId = json['projectId'] ?? '';
    storageBucket = json['storageBucket'] ?? '';
    messagingSenderId = json['messagingSenderId'] ?? '';
    appId = json['appId'] ?? '';
  }
}

class StorageConnInfo {
  String apiKey = "";
  String appId = "";
  String storageURL = ""; // appwrite endpoint
  String projectId = ""; // appwrite projectId
  String bucketId = ""; // appwrite storage bucketId, firebase user folder path
  String messagingSenderId = "";

  void fromJson(Map<String, dynamic> json) {
    apiKey = json['apiKey'] ?? '';
    appId = json['appId'] ?? '';
    storageURL = json['storageURL'] ?? '';
    projectId = json['projectId'] ?? '';
    //bucketId = json['bucketId'] ?? '';
    messagingSenderId = json['messagingSenderId'] ?? '';
  }
}

class SocketConnInfo {
  String serverUrl = "";
  String serverPort = "";
  String roomId = '';

  void fromJson(Map<String, dynamic> json) {
    serverUrl = json['serverUrl'];
    serverPort = json['serverPort'];
    serverPort = json['roomId'] ?? '';
  }
}

abstract class AbsServerConfig {
  final String enterprise;
  DBConnInfo dbConnInfo = DBConnInfo();
  StorageConnInfo storageConnInfo = StorageConnInfo();
  SocketConnInfo socketConnInfo = SocketConnInfo();
  AbsServerConfig(this.enterprise);

  Map<String, dynamic> jsonMap = {};

  Future<void> loadAsset(/*BuildContext context*/) async {
    String cipherString = '';
    try {
      cipherString = await rootBundle.loadString('assets/${enterprise}_config.json');
      //jsonString = await DefaultAssetBundle.of(context).loadString('assets/${enterprise}_config.json');
      logger.info('assets/${enterprise}_config.json loaded');
    } catch (e) {
      logger.info('assets/${enterprise}_config.json not exist, hycop_config.json will be used');
      try {
        cipherString = await rootBundle.loadString('assets/hycop_config.json');
        //jsonString = await DefaultAssetBundle.of(context).loadString('assets/hycop_config.json');
        logger.info('assets/hycop_config.json loaded');
      } catch (e) {
        logger.severe('load assets/hycop_config.json failed', e);
        return;
      }
    }
    //logger.finest(cipherString);
    String jsonString = await MyEncrypt.toDecrypt(cipherString);
    //logger.finest(jsonString);
    jsonMap = jsonDecode(jsonString);
  }

  void initConn(Map<String, dynamic> configMap) {
    dbConnInfo.fromJson(configMap['dbConnInfo']);
    storageConnInfo.fromJson(configMap['storageConnInfo']);
    socketConnInfo.fromJson(configMap['socketConnInfo']);
  }
}

class FirebaseConfig extends AbsServerConfig {
  FirebaseConfig({String enterprise = 'Demo'}) : super(enterprise);
  @override
  Future<void> loadAsset() async {
    await super.loadAsset();
    initConn(jsonMap['FirebaseConfig']);
  }
}

class AppwriteConfig extends AbsServerConfig {
  AppwriteConfig({String enterprise = 'Demo'}) : super(enterprise);
  @override
  Future<void> loadAsset() async {
    await super.loadAsset();
    initConn(jsonMap['AppwriteConfig']);
  }
}

class SupabaseConfig extends AbsServerConfig {
  SupabaseConfig({String enterprise = 'Demo'}) : super(enterprise);
  @override
  Future<void> loadAsset() async {
    await super.loadAsset();
    initConn(jsonMap['SupabaseConfig']);
  }
}

class AssetConfig extends AbsServerConfig {
  AssetConfig({String enterprise = 'Demo'}) : super(enterprise);

  int _savePeriod = 1000;
  String _apiServerUrl = '';
  String _googleOAuthCliendId = '';

  String _guestUserId = '';
  String _guestUserPassword = '';

  int get savePeriod => _savePeriod;
  String get apiServerUrl => _apiServerUrl;
  String get googleOAuthCliendId => _googleOAuthCliendId;
  String get guestUserId => _guestUserId;
  String get guestUserPassword => _guestUserPassword;

  @override
  Future<void> loadAsset(/*BuildContext context*/) async {
    await super.loadAsset(/*context*/);
    final dynamic configMap = jsonMap['AssetConfig'];
    _savePeriod = configMap['savePeriod'] ?? 1000;
    _apiServerUrl = configMap['apiServerUrl'] ?? 'http://localhost:3000';
    if (_apiServerUrl[_apiServerUrl.length - 1] == '/') {
      _apiServerUrl = _apiServerUrl.substring(0, _apiServerUrl.length - 1);
    }
    _googleOAuthCliendId = configMap['googleOAuthCliendId'] ?? '';
    _guestUserId = configMap['guestUserId'] ?? '';
    _guestUserPassword = configMap['guestUserPassword'] ?? '';
  }
}

HycopConfig? myConfig;

class HycopConfig {
  late AssetConfig config;
  AbsServerConfig? serverConfig;

  HycopConfig() {
    config = AssetConfig(enterprise: HycopFactory.enterprise);
    config.loadAsset();
    if (HycopFactory.serverType == ServerType.firebase) {
      serverConfig = FirebaseConfig(enterprise: HycopFactory.enterprise);
    } else if (HycopFactory.serverType == ServerType.appwrite) {
      serverConfig = AppwriteConfig(enterprise: HycopFactory.enterprise);
    } else if (HycopFactory.serverType == ServerType.supabase) {
      serverConfig = SupabaseConfig(enterprise: HycopFactory.enterprise);
    }
    //serverConfig?.loadAsset();
  }
}
