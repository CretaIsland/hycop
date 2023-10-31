// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:appwrite/appwrite.dart';

import '../../common/util/config.dart';
import '../database/abs_database.dart';
import '../../common/util/logger.dart';
import '../hycop_factory.dart';
import 'abs_realtime.dart';

class AppwriteRealtime extends AbsRealtime {
  StreamSubscription<dynamic>? realtimeListener;
  RealtimeSubscription? subscription;

  @override
  Future<void> initialize() async {
    //await HycopFactory.initAll();
    // 일반 reealTime DB 사용의 경우.
  }

  @override
  Future<void> start() async {
    await initialize();
    if (subscription != null) {
      return;
    }
    String dbId = myConfig!.serverConfig!.dbConnInfo.appId;
    String ch = 'databases.$dbId.collections.hycop_delta.documents';
    subscription = Realtime(AbsDatabase.awDBConn!).subscribe([ch]);
    realtimeListener = subscription!.stream.listen((event) {
      processEvent(event.payload);
    });
  }

  @override
  Future<void> startTemp(String? rtKey) async {
    realTimeKey = rtKey;
    if (realTimeKey == null || realTimeKey!.isEmpty) {
      return;
    }

    await initialize();

    logger.finest('AppwriteRealtime startTemp()');
   
      logger.finest('listener restart $realTimeKey, $lastUpdateTimeStr');
      if (subscription != null) {
        return;
      }
      String dbId = myConfig!.serverConfig!.dbConnInfo.appId;
      String ch = 'databases.$dbId.collections.hycop_delta.documents';
      subscription = Realtime(AbsDatabase.awDBConn!).subscribe([ch]);
      realtimeListener = subscription!.stream.listen((event) {
        // appwrite 는 아마도 lastUpdateTime 을 기록할 필요가 없는 것으로 보인다.
        // 어차피 새로워진 것만 도착하기 때문인것 같다.
        // 여기서 realTimeKey 가 다르면 버린다.
        String? eventRealTimeKey = event.payload['realTimeKey'];
        if (eventRealTimeKey == null) {
          return;
        }
        if (eventRealTimeKey != realTimeKey) {
          return;
        }
        processEvent(event.payload);
      });
    //});
  }

  @override
  void stop() {
    subscription?.close();
    realtimeListener?.cancel();
    realtimeListener = null;
    subscription = null;
  }

  @override
  Future<bool> setDelta({
    required String directive,
    required String mid,
    required Map<String, dynamic>? delta,
  }) async {
    await initialize();
    Map<String, dynamic> input = makeData(directive: directive, mid: mid, delta: delta);
    try {
      final Map<String, dynamic> target = await HycopFactory.dataBase!.getData('hycop_delta', mid);
      if (target.isEmpty) {
        logger.finest('createDelta = ${input.toString()}');
        HycopFactory.dataBase!.createData('hycop_delta', mid, input);
        return true;
      }
      logger.finest('setDelta = ${input.toString()}');
      HycopFactory.dataBase!.setData('hycop_delta', mid, input);
      return true;
    } catch (e) {
      logger.finest('database error $e');
      return false;
    }
  }
}
