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

  DateTime lastUpdateTime = DateTime.now(); // used only firebase
  String lastUpdateTimeStr = HycopUtils.dateTimeToDB(DateTime.now()); // used only firebase
  DateTime maxDataTime = DateTime.now();
  String collcetion_prefix = 'hycop';
  String? realTimeKey;

  // 최근 수신된 15개의 delta 값들을 저장하는 리스트
  final List<String> _recentDeltas = [];
  bool isDuplicationEvent(String delta, {int maxDuration = 15}) {
    bool retval = _recentDeltas.contains(delta);
    if (retval == false) {
      _recentDeltas.add(delta);
      // 리스트가 15개를 넘으면 가장 오래된 항목 삭제
      if (_recentDeltas.length > maxDuration) {
        _recentDeltas.removeAt(0);
      }
    }
    return retval;
  }

  Future<void> initialize();
  Future<void> start();
  Future<void> startTemp(String? rtKey) async {
    if (rtKey == null) {
      await start();
      return;
    }
  }

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
      Map<
          String,
          void Function(String listenerId, String directive, String userId,
              Map<String, dynamic> dataModel)>> listenerMap = {};

  void addListener(
      String listenerId,
      String collectionId,
      void Function(
              String listenerId, String directive, String userId, Map<String, dynamic> dataModel)
          listener) {
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
    if (item is DateTime) {
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
    String now = HycopUtils.dateTimeToDB(DateTime.now());
    input['directive'] = directive;
    input['collectionId'] = HycopUtils.collectionFromMid(mid, collcetion_prefix);
    input['mid'] = mid; //'book=3ecb527f-4f5e-4350-8705-d5742781451b';
    input['userId'] = AccountManager.currentLoginUser.email;
    input['deviceId'] = myDeviceId;
    input['updateTime'] = now;
    input['delta'] = (delta != null) ? json.encode(delta, toEncodable: myEncode) : '';
    if (delta != null) {
      input['realTimeKey'] = delta['realTimeKey'] ?? '';
    }
    return input;
  }

  @protected
  void processEvent(Map<String, dynamic> mapValue) {
    String? dataTimeStr = mapValue["updateTime"];
    if (dataTimeStr == null) {
      return;
    }
    if (realTimeKey == null) {
      lastUpdateTimeStr = dataTimeStr;
    } else {
      DateTime dataTime = DateTime.parse(dataTimeStr);
      int dataTimeSec = dataTime.microsecondsSinceEpoch;
      if (dataTimeSec > maxDataTime.microsecondsSinceEpoch) {
        maxDataTime = dataTime;
      }
      if (dataTimeSec < lastUpdateTime.microsecondsSinceEpoch) {
        return;
      }
    }
    String? fromDeviceId = mapValue["deviceId"];
    if (fromDeviceId == null) {
      logger.info('!!! deviceId is null !!! ');
      return;
    }
    if (fromDeviceId == myDeviceId) {
      logger.info('!!! deviceId same !!! $myDeviceId');
      //print('same deviceId=$fromDeviceId &&&&&&&&&&&&&&&&&&&&&&&&');
      return;
    }

    // mid 와 delta 가 이전 값과 완전히 동일한 데이터도 버려야 한다.
    String? delta = mapValue["delta"];
    if (delta == null || delta.isEmpty || isDuplicationEvent(delta) == true) {
      logger.info('!!! same data  !!!');
      return;
    }

    logger.info('event.payload=$mapValue');
    logger.info('---- matched !!!  ----');
    logger.info('event received=$fromDeviceId, $realTimeKey');

    String directive = mapValue["directive"] ?? '';
    // = mapValue["mid"] ?? '';
    String collectionId = mapValue["collectionId"] ?? '';
    String userId = mapValue["userId"] ?? '';
    //print('$lastUpdateTimeStr,$directive,$collectionId,$userId -----------------------------');

    Map<String, dynamic> dataMap = json.decode(delta) as Map<String, dynamic>;
    String? parentMid = dataMap['parentMid'] as String?;
    if (parentMid == null || parentMid.isEmpty) {
      //print('parentMid is null');
      return;
    }
    for (var key in listenerMap.keys) {
      //print('parentMid=$parentMid, key=$key');
      if (key != parentMid) continue;
      var map = listenerMap[key];
      map![collectionId]?.call(key, directive, userId, dataMap);
      break;
    }
  }
}
