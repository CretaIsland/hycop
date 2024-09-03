// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:collection';
//import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
//import '../hycop_factory.dart';
import '../utils/hycop_utils.dart';
import 'abs_realtime.dart';

class FirebaseRealtime extends AbsRealtime {
  DatabaseReference? _db;
  StreamSubscription<DatabaseEvent>? _deltaStream;
  bool _isListenComplete = true;
  //Timer? _listenTimer;

  @override
  Future<void> initialize() async {
    if (AbsRealtime.fbRTApp == null) {
      //await HycopFactory.initAll();
      AbsRealtime.setFirebaseApp(await Firebase.initializeApp(
          name: "realTime",
          options: FirebaseOptions(
              databaseURL: myConfig!.serverConfig.dbConnInfo.databaseURL,
              apiKey: myConfig!.serverConfig.dbConnInfo.apiKey,
              appId: myConfig!.serverConfig.dbConnInfo.appId,
              storageBucket: myConfig!.serverConfig.dbConnInfo.storageBucket,
              messagingSenderId: myConfig!.serverConfig.dbConnInfo.messagingSenderId,
              projectId: myConfig!.serverConfig.dbConnInfo.projectId)));
      logger.finest('realTime initialized');
    }
    // ignore: prefer_conditional_assignment
    if (_db == null) {
      _db = FirebaseDatabase.instanceFor(app: AbsRealtime.fbRTApp!).ref();
    }

    // for realtime
  }

  @override
  Future<void> start() async {
    realTimeKey = null;
    await initialize();
    logger.finest('FirebaseRealtime start()');
    //if (_listenTimer != null) return;
    logger.finest('FirebaseRealtime start...()');
    //_listenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    if (_isListenComplete) {
      _isListenComplete = false;
      logger.finest('listener restart $lastUpdateTimeStr');
      _deltaStream?.cancel();
      _deltaStream = _db!
          .child('hycop_delta')
          .orderByChild('updateTime')
          .startAfter(lastUpdateTimeStr)
          .onValue
          .listen((event) => _listenCallback(event, ''));
    }
    //});
  }

  @override
  Future<void> startTemp(String? rtKey) async {
    // skpark 2024.06.14 현재 firebase bug 로 인해 임시로 막아둠.
    //return;

    realTimeKey = rtKey;
    if (realTimeKey == null || realTimeKey!.isEmpty) {
      return;
    }

    await initialize();

    logger.finest('FirebaseRealtime startTemp()');
    //if (_listenTimer != null) return;
    logger.finest('FirebaseRealtime startTemp...()');
    //_listenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    if (_isListenComplete) {
      _isListenComplete = false;
      logger.finest('listener restart $realTimeKey, $lastUpdateTimeStr');
      _deltaStream?.cancel();
      _deltaStream = _db!
          .child('hycop_delta')
          // .orderByChild('updateTime')
          // .startAfter(lastUpdateTimeStr)
          .orderByChild('realTimeKey')
          //.startAfter('$realTimeKey-$lastUpdateTimeStr')
          .equalTo(realTimeKey)
          .onValue
          .listen((event) => _listenCallback(event, ''));
    }
    //});
  }

  void _listenCallback(DatabaseEvent event, String hint) {
    logger.finest('_listenCallback invoked');
    if (event.snapshot.value == null) {
      return;
    }

    try {
      //print('event.snapshot.value: ${event.snapshot.value}');
      //print('hint: $hint, $realTimeKey');
      if (event.snapshot.value is Map<String, dynamic>) {
        logger.finest('event.snapshot.value is Map<String, dynamic> type');
        final rows = event.snapshot.value as Map<String, dynamic>;
        rows.forEach((mapKey, mapValue) {
          processEvent(mapValue);
        });
        if (realTimeKey != null) {
          lastUpdateTime = maxDataTime;
          lastUpdateTimeStr = HycopUtils.dateTimeToDB(maxDataTime);
          logger.finest('[$hint end $lastUpdateTimeStr]-------------------------------------');
        }
        //_isListenComplete = true;
        return;
      } else if (event.snapshot.value is LinkedHashMap<Object?, Object?>) {
        logger.finest('event.snapshot.value is LinkedHashMap<Object?, Object?> type');
        final linkedMap = event.snapshot.value as LinkedHashMap<Object?, Object?>;
        final Map<String, dynamic> rows = linkedMap.map((key, value) {
          return MapEntry(key.toString(), value);
        });

        rows.forEach((mapKey, mapValue) {
          // 여기서 mapValue 가 LinkedMap<Object?, Object?> 이다.
          // 그런데  LinkedMap 은 세상에 존재하지 않는 구조체이다.
          // 그래서 아래와 같이 처리한다.
          Map<String, dynamic> data = {};
          Map<Object?, Object?> temp = mapValue as Map<Object?, Object?>;
          temp.forEach((key, value) {
            data[key.toString()] = value;
          });

          //Map<String, dynamic> data = jsonDecode(mapValue.toString());
          processEvent(data);
        });

        if (realTimeKey != null) {
          lastUpdateTime = maxDataTime;
          lastUpdateTimeStr = HycopUtils.dateTimeToDB(maxDataTime);
          logger.finest('[$hint end $lastUpdateTimeStr]-------------------------------------');
        }
        //_isListenComplete = true;
        return;
        //} else if (event.snapshot.value is LinkedMap<Object?, Object?>) {
      }
      logger.severe(
          'event.snapshot.value is ${event.snapshot.value.runtimeType}, it is not expected type....');
      // event.snapshot.value is LinkedMap<Object?, Object?>, it is not expected type....
      // LinkedMap  을 Map 으로 바꿀 수 있는 방법이 없다...

      //_isListenComplete = true;
    } catch (e) {
      logger.severe('Error: $e');
    }
  }

  @override
  void stop() {
    logger.finest('listener stop...');
    _isListenComplete = true;
    _deltaStream?.cancel();
    //_listenTimer?.cancel();
    //_listenTimer = null;
  }

  @override
  Future<bool> setDelta({
    required String directive,
    required String mid,
    required Map<String, dynamic>? delta,
  }) async {
    await initialize();

    Map<String, dynamic> input = makeData(directive: directive, mid: mid, delta: delta);
    logger.finest('setDelta = ${input.toString()}');

    try {
      await _db!.child('hycop_delta').child(mid).set(input);
      logger.finest("hycop_delta sample data created");
      return true;
    } catch (e) {
      logger.severe("hycop_delta SET DB ERROR : $e");
      return false;
    }
  }
}
