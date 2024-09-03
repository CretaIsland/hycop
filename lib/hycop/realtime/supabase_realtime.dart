import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/util/logger.dart';
import 'abs_realtime.dart';

class SupabaseRealtime extends AbsRealtime {
  bool _isListenComplete = true;
  RealtimeChannel? _deltaChannel;
  //Timer? _listenTimer;

  @override
  Future<void> initialize() async {
    if (AbsRealtime.sbRTConn == null) {
      // await HycopFactory.initAll();
      logger.finest('initialize');
      // await Supabase.initialize(
      //   url: myConfig!.serverConfig.dbConnInfo.databaseURL,
      //   anonKey: myConfig!.serverConfig.dbConnInfo.apiKey,
      // );
      AbsRealtime.setSupabaseApp(Supabase.instance.client);
      //AbsRealtime.sbRTConn = null;
    }

    assert(AbsRealtime.sbRTConn != null);
    // for realtime
  }

  @override
  Future<void> start() async {
    realTimeKey = null;
    await initialize();
    logger.finest('SupabaseRealtime start()');
    if (_isListenComplete) {
      _isListenComplete = false;
      logger.finest('listener restart $lastUpdateTimeStr');
      _deltaChannel = Supabase.instance.client
          .channel('public:hycop_delta')
          .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'hycop_delta',
              //filter: ,
              callback: (PostgresChangePayload payload) {
                //print('Change received: ${payload.toString()}');
                processEvent(payload.newRecord);
              })
          .subscribe();
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
    logger.finest('SupabaseRealtime start()');
    if (_isListenComplete) {
      _isListenComplete = false;
      logger.finest('listener restart $lastUpdateTimeStr');
      Supabase.instance.client
          .channel('public:hycop_delta')
          .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'hycop_delta',
              filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq, column: "realTimeKey", value: realTimeKey),
              callback: (PostgresChangePayload payload) {
                //print('Change received: ${payload.toString()}');
                processEvent(payload.newRecord);
              })
          .subscribe();
    }
    //});
  }

  // void _listenCallback(DatabaseEvent event, String hint) {
  //   logger.finest('_listenCallback invoked');
  //   if (event.snapshot.value == null) {
  //     return;
  //   }

  //   try {
  //     //print('event.snapshot.value: ${event.snapshot.value}');
  //     //print('hint: $hint, $realTimeKey');
  //     if (event.snapshot.value is Map<String, dynamic>) {
  //       logger.finest('event.snapshot.value is Map<String, dynamic> type');
  //       final rows = event.snapshot.value as Map<String, dynamic>;
  //       rows.forEach((mapKey, mapValue) {
  //         processEvent(mapValue);
  //       });
  //       if (realTimeKey != null) {
  //         lastUpdateTime = maxDataTime;
  //         lastUpdateTimeStr = HycopUtils.dateTimeToDB(maxDataTime);
  //         logger.finest('[$hint end $lastUpdateTimeStr]-------------------------------------');
  //       }
  //       //_isListenComplete = true;
  //       return;
  //     } else if (event.snapshot.value is LinkedHashMap<Object?, Object?>) {
  //       logger.severe('event.snapshot.value is LinkedHashMap<Object?, Object?> type');
  //       final linkedMap = event.snapshot.value as LinkedHashMap<Object?, Object?>;
  //       final Map<String, dynamic> rows = linkedMap.map((key, value) {
  //         return MapEntry(key.toString(), value);
  //       });

  //       rows.forEach((mapKey, mapValue) {
  //         print('mapKey: $mapKey, mapValue: $mapValue');
  //         // 여기서 mapValue 가 LinkedMap<Object?, Object?> 이다.
  //         // 그런데  LinkedMap 은 세상에 존재하지 않는 구조체이다.
  //         // 그래서 아래와 같이 처리한다.
  //         Map<String, dynamic> data = {};
  //         Map<Object?, Object?> temp = mapValue as Map<Object?, Object?>;
  //         temp.forEach((key, value) {
  //           data[key.toString()] = value;
  //         });

  //         //Map<String, dynamic> data = jsonDecode(mapValue.toString());
  //         processEvent(data);
  //       });

  //       if (realTimeKey != null) {
  //         lastUpdateTime = maxDataTime;
  //         lastUpdateTimeStr = HycopUtils.dateTimeToDB(maxDataTime);
  //         logger.finest('[$hint end $lastUpdateTimeStr]-------------------------------------');
  //       }
  //       //_isListenComplete = true;
  //       return;
  //       //} else if (event.snapshot.value is LinkedMap<Object?, Object?>) {
  //     }
  //     logger.severe(
  //         'event.snapshot.value is ${event.snapshot.value.runtimeType}, it is not expected type....');
  //     // event.snapshot.value is LinkedMap<Object?, Object?>, it is not expected type....
  //     // LinkedMap  을 Map 으로 바꿀 수 있는 방법이 없다...

  //     //_isListenComplete = true;
  //   } catch (e) {
  //     logger.severe('Error: $e');
  //   }
  // }

  @override
  void stop() {
    logger.finest('listener stop...');
    _isListenComplete = true;
    if (_deltaChannel != null) {
      Supabase.instance.client.removeChannel(_deltaChannel!);
      _deltaChannel = null;
    }
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
      SupabaseQueryBuilder fromRef = AbsRealtime.sbRTConn!.from('hycop_delta');
      fromRef.upsert(input, onConflict: 'mid', ignoreDuplicates: true);
      logger.finest("hycop_delta sample data created");
      return true;
    } catch (e) {
      logger.severe("hycop_delta SET DB ERROR : $e");
      return false;
    }
  }
}
