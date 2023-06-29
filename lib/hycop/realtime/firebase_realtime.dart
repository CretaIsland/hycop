// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
//import '../hycop_factory.dart';
import 'abs_realtime.dart';

class FirebaseRealtime extends AbsRealtime {
  DatabaseReference? _db;
  StreamSubscription<DatabaseEvent>? _deltaStream;
  bool isListenComplete = true;
  Timer? _listenTimer;

  @override
  Future<void> initialize() async {
    if (AbsRealtime.fbRTApp == null) {
      //await HycopFactory.initAll();
      AbsRealtime.setFirebaseApp(await Firebase.initializeApp(
          name: "realTime",
          options: FirebaseOptions(
              databaseURL: myConfig!.serverConfig!.dbConnInfo.databaseURL,
              apiKey: myConfig!.serverConfig!.dbConnInfo.apiKey,
              appId: myConfig!.serverConfig!.dbConnInfo.appId,
              storageBucket: myConfig!.serverConfig!.dbConnInfo.storageBucket,
              messagingSenderId: myConfig!.serverConfig!.dbConnInfo.messagingSenderId,
              projectId: myConfig!.serverConfig!.dbConnInfo.projectId)));
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
    await initialize();
    logger.finest('FirebaseRealtime start()');
    if (_listenTimer != null) return;
    logger.finest('FirebaseRealtime start...()');
    _listenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isListenComplete) {
        isListenComplete = false;
        logger.finest('listener restart $lastUpdateTime');
        _deltaStream?.cancel();
        _deltaStream = _db!
            .child('hycop_delta')
            .orderByChild('updateTime')
            .startAfter(lastUpdateTime)
            .onValue
            .listen((event) => _listenCallback(event, ''));
      }
    });
  }

  @override
  Future<void> startTemp(String? realTimeKey) async {
    if (realTimeKey == null || realTimeKey.isEmpty) {
      return;
    }

    await initialize();

    logger.finest('FirebaseRealtime startTemp()');
    if (_listenTimer != null) return;
    logger.finest('FirebaseRealtime startTemp...()');
    _listenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isListenComplete) {
        isListenComplete = false;
        logger.finest('listener restart $realTimeKey-$lastUpdateTime');
        _deltaStream?.cancel();
        _deltaStream = _db!
            .child('hycop_delta')
            //.orderByChild('updateTime')
            //.startAfter(lastUpdateTime)
            .orderByChild('realTimeKey')
            .startAfter('$realTimeKey-$lastUpdateTime')
            //.equalTo(realTimeKey)
            .onValue
            .listen((event) => _listenCallback(event, ''));
      }
    });
  }

  void _listenCallback(DatabaseEvent event, String hint) {
    logger.finest('_listenCallback invoked');
    if (event.snapshot.value == null) {
      return;
    }
    DateTime now = DateTime.now();
    final rows = event.snapshot.value as Map<String, dynamic>;

    logger.finest('[$hint Listen]------------------------------');
    rows.forEach((mapKey, mapValue) {
      processEvent(mapValue);
    });
    logger.finest('[$hint end ${now.toString()}]-------------------------------------');
    isListenComplete = true;
  }

  @override
  void stop() {
    logger.finest('listener stop...');
    isListenComplete = true;
    _deltaStream?.cancel();
    _listenTimer?.cancel();
    _listenTimer = null;
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
