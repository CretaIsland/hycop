// ignore_for_file: depend_on_referenced_packages, non_constant_identifier_names

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import '../../common/util/logger.dart';
import '../utils/hycop_utils.dart';
import '../account/account_manager.dart';
import 'package:uuid/uuid.dart';

abstract class AbsRealtime {
  static String myDeviceId = const Uuid().v4();
  //connection info
  static FirebaseApp? _fbRTApp; // firebase only RealTime connetion
  static FirebaseApp? get fbRTApp => _fbRTApp;
  @protected
  static void setFirebaseApp(FirebaseApp fb) => _fbRTApp = fb;

  String lastUpdateTime = HycopUtils.dateTimeToDB(DateTime.now()); // used only firebase
  String collcetion_prefix = 'hycop';

  Future<void> initialize();
  Future<void> start();
  void setPrefix(String prefix) {
    collcetion_prefix = prefix;
  }

  void stop();
  void clearListener() {
    logger.fine('clearListener()');
    listenerMap.clear();
  }

  Future<bool> setDelta({
    required String directive,
    required String mid,
    required Map<String, dynamic>? delta,
  });

  @protected
  Map<
          String,
          Map<String,
              void Function(String directive, String userId, Map<String, dynamic> dataModel)>>
      listenerMap = {};

  void addListener(String listenerId, String collectionId,
      void Function(String directive, String userId, Map<String, dynamic> dataModel) listener) {
    if (listenerMap[listenerId] == null) {
      listenerMap[listenerId] = {};
    }
    var map = listenerMap[listenerId]!;
    map[collectionId] = listener;
  }

  void removeListener(String listenerId, String collectionId) {
    listenerMap[listenerId]?.remove(collectionId);
  }

  dynamic myEncode(dynamic item) {
    if(item is DateTime) {
      //return item.toIso8601String();
      return item.toString();
    }
    return item;
  }

  @protected
  Map<String, dynamic> makeData({
    required String directive,
    required String mid,
    required Map<String, dynamic>? delta,
  }) {
    Map<String, dynamic> input = {};
    input['directive'] = directive;
    input['collectionId'] = HycopUtils.collectionFromMid(mid, collcetion_prefix);
    input['mid'] = mid; //'book=3ecb527f-4f5e-4350-8705-d5742781451b';
    input['userId'] = AccountManager.currentLoginUser.email;
    input['deviceId'] = myDeviceId;
    input['updateTime'] = HycopUtils.dateTimeToDB(DateTime.now());
    input['delta'] = (delta != null) ? json.encode(delta, toEncodable: myEncode) : '';

    return input;
  }

  @protected
  void processEvent(Map<String, dynamic> mapValue) {
    lastUpdateTime = mapValue["updateTime"] ?? '';

    String fromDeviceId = mapValue["deviceId"] ?? '';
    if (fromDeviceId == myDeviceId) {
      logger.finest('same deviceId=$fromDeviceId');
      return;
    }
    String directive = mapValue["directive"] ?? '';
    // = mapValue["mid"] ?? '';
    String collectionId = mapValue["collectionId"] ?? '';
    String userId = mapValue["userId"] ?? '';
    String delta = mapValue["delta"] ?? '';
    logger.finest('$lastUpdateTime,$directive,$collectionId,$userId');

    Map<String, dynamic> dataMap = json.decode(delta) as Map<String, dynamic>;

    for (var ele in listenerMap.values) {
      ele[collectionId]?.call(directive, userId, dataMap);
    }
  }
}
