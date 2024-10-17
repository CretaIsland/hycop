// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../common/util/logger.dart';
import 'abs_database.dart';

class SupabaseDatabase extends AbsDatabase {
  int? startAfter;

  @override
  Future<void> initialize() async {
    if (AbsDatabase.sbDBConn == null) {
      // await HycopFactory.initAll();
      logger.finest('initialize');
      // await Supabase.initialize(
      //   url: myConfig!.serverConfig.dbConnInfo.databaseURL,
      //   anonKey: myConfig!.serverConfig.dbConnInfo.apiKey,
      // );
      AbsDatabase.setSupabaseApp(Supabase.instance.client);

      //AbsDatabase.sbDBConn = null;
    }

    assert(AbsDatabase.sbDBConn != null);
  }

  @override
  Future<Map<String, dynamic>> getData(String collectionId, String mid) async {
    await initialize();
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    Map<String, dynamic>? result = await fromRef.select().eq('mid', mid).maybeSingle();
    return result;
    return {};
  }

  @override
  Future<List> getAllData(String collectionId) async {
    await initialize();

    final List resultList = [];
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    await fromRef.select().then((snapshot) {
      for (var result in snapshot) {
        resultList.add(result);
      }
    });
    return resultList;
  }

  @override
  Future<void> setData(String collectionId, String mid, Map<dynamic, dynamic> data) async {
    await initialize();

    data['mid'] = mid;

    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    await fromRef.upsert(data, onConflict: 'mid');
    logger.finest('$mid saved');
  }

  @override
  Future<void> updateData(String collectionId, String mid, Map<dynamic, dynamic> data) async {
    await initialize();

    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    await fromRef.update(data).eq('mid', mid);
    logger.finest('$mid saved');
  }

  @override
  Future<void> createData(String collectionId, String mid, Map<dynamic, dynamic> data) async {
    await initialize();

    logger.finest('createData... $mid!');
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    await fromRef.upsert(data, onConflict: 'mid', ignoreDuplicates: true);
    logger.finest('$mid! created');
  }

  @override
  Future<List> simpleQueryData(String collectionId,
      {required String name,
      required String value,
      required String orderBy,
      bool descending = true,
      int? limit,
      int? offset}) async {
    await initialize();

    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    if (limit != null) {
      if (offset != null) {
        return await fromRef
            .select()
            .eq(name, value)
            .order(orderBy, ascending: !descending)
            .limit(limit)
            .range(offset, offset + limit);
      }
      return await fromRef
          .select()
          .eq(name, value)
          .order(orderBy, ascending: !descending)
          .limit(limit);
    }
    return await fromRef.select().eq(name, value).order(orderBy, ascending: !descending);
  }

  @override
  Future<List> queryData(
    String collectionId, {
    required Map<String, dynamic> where,
    required String orderBy,
    bool descending = true,
    int? limit,
    int? offset,
    List<Object?>? startAfter, // 사용안됨.
  }) async {
    logger.finest('queryData $collectionId');
    await initialize();
    assert(AbsDatabase.sbDBConn != null);

    if (AbsDatabase.sbDBConn == null) {
      logger.severe('sbDBConn is null');
      return [];
    }
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    PostgrestFilterBuilder filterBuilder = fromRef.select();
    where.forEach((key, value) {
      filterBuilder = queryMaker('"$key"', OperType.isEqualTo, value, filterBuilder);
    });

    // Map<String, Object> objWhere = {};
    // where.forEach((key, value) {
    //   objWhere[key] = value;
    // });

    if (limit != null) {
      if (offset != null) {
        return await filterBuilder
            .order(orderBy, ascending: !descending)
            .limit(limit)
            .range(offset, offset + limit);
      }
      return await filterBuilder.order(orderBy, ascending: !descending).limit(limit);
    }
    return await filterBuilder.order(orderBy, ascending: !descending);
  }

  @override
  Future<bool> isNameExist(
    String collectionId, {
    required String value,
    String name = 'name',
  }) async {
    await initialize();
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    List resultList = await fromRef.select().eq(name, value);
    return resultList.isNotEmpty;
  }

  PostgrestFilterBuilder queryMaker(
      String column, OperType operType, dynamic value, PostgrestFilterBuilder filterBuilder) {
    logger.fine('queryMaker : $column $operType, $value');
    switch (operType) {
      case OperType.isEqualTo:
        if (value is bool) {
          //print('This is boolean type ------------------------------');
          return filterBuilder.eq(column, value ? 'true' : 'false');
        }
        return filterBuilder.eq(column, value);
      case OperType.isGreaterThan:
        return filterBuilder.gt(column, value);
      case OperType.isGreaterThanOrEqualTo:
        return filterBuilder.gte(column, value);
      case OperType.isLessThan:
        return filterBuilder.lt(column, value);
      case OperType.isLessThanOrEqualTo:
        return filterBuilder.lte(column, value);
      case OperType.isNotEqualTo:
        return filterBuilder.neq(column, value);
      case OperType.arrayContains: //cs  : contains
        List data = [];
        if (value is List<String>) {
          data = value;
          //print('string type case-------------list:$data');
        } else if (value is String) {
          //print('list type case-------------list:$data');
          //data = jsonStringToList(value);
          data = value.split(',');
        }
        List<String> tempList = data.map((item) => '"$item"').toList();
        String filterString = '{${tempList.join(',')}}'; // Supabase에서는 {}가 리스트를 의미하므로 묶어 주어야 합니다.
        //print('---------filterString : $filterString');
        return filterBuilder.filter(column, "cs", filterString);
      case OperType.arrayContainsAny: // ov : overlap
        List data = [];
        if (value is List<String>) {
          data = value;
          //print('string type case-------------list:$data');
        } else if (value is String) {
          //print('list type case-------------list:$data');
          //data = jsonStringToList(value);
          data = value.split(',');
        }
        List<String> tempList = data.map((item) => '"$item"').toList();
        String filterString = '{${tempList.join(',')}}'; // Supabase에서는 {}가 리스트를 의미하므로 묶어 주어야 합니다.
        //print('---------filterString : $filterString');
        return filterBuilder.filter(column, "ov", filterString);
      case OperType.whereIn:
        List data = [];
        if (value is List<String>) {
          data = value;
          //print('string type case-------------list:$data');
        } else if (value is String) {
          //data = jsonStringToList(value);
          data = value.split(',');
          //print('list type case-------------list:$data');
        }
        return filterBuilder.inFilter(column, data);

      case OperType.whereNotIn:
        return filterBuilder.not(column, "in", value);
      case OperType.isNull:
        return filterBuilder.isFilter(column, null);
      case OperType.textSearch:
        return filterBuilder.textSearch(column, value);
    }
    //return filterBuilder;
  }

  SupabaseStreamBuilder queryMakerStream(
      String column, QueryValue value, SupabaseStreamFilterBuilder streamBuilder) {
    switch (value.operType) {
      case OperType.isEqualTo:
        return streamBuilder.eq(column, value.value);
      case OperType.isGreaterThan:
        streamBuilder.gt(column, value.value);
        break;
      case OperType.isGreaterThanOrEqualTo:
        streamBuilder.gte(column, value.value);
        break;
      case OperType.isLessThan:
        streamBuilder.lt(column, value.value);
        break;
      case OperType.isLessThanOrEqualTo:
        streamBuilder.lte(column, value.value);
        break;
      case OperType.isNotEqualTo:
        streamBuilder.neq(column, value.value);
        break;
      case OperType.arrayContains: //cs  : contains
        logger.severe('supabase streamBuilder does not support arrayContains');
        break;
      // case OperType.arrayContains: //cs  : contains
      //   List data = [];
      //   if (value is List<String>) {
      //     data = value;
      //     //print('string type case-------------list:$data');
      //   } else if (value is String) {
      //     //print('list type case-------------list:$data');
      //     //data = jsonStringToList(value);
      //     data = value.split(',');
      //   }
      //   List<String> tempList = data.map((item) => '"$item"').toList();
      //   String filterString = '{${tempList.join(',')}}'; // Supabase에서는 {}가 리스트를 의미하므로 묶어 주어야 합니다.
      //   //print('---------filterString : $filterString');
      //   streamBuilder.filter(column, "cs", filterString);
      //   break;
      case OperType.arrayContainsAny: // ov : overlap
        logger.severe('supabase streamBuilder does not support arrayContainsAny');
        break;
      //   List data = [];
      //   if (value is List<String>) {
      //     data = value;
      //     //print('string type case-------------list:$data');
      //   } else if (value is String) {
      //     //print('list type case-------------list:$data');
      //     //data = jsonStringToList(value);
      //     data = value.split(',');
      //   }
      //   List<String> tempList = data.map((item) => '"$item"').toList();
      //   String filterString = '{${tempList.join(',')}}'; // Supabase에서는 {}가 리스트를 의미하므로 묶어 주어야 합니다.
      //   //print('---------filterString : $filterString');
      //   streamBuilder.filter(column, "ov", filterString);
      //   break;
      case OperType.whereIn:
        List<Object> data = [];
        if (value.value is List<String>) {
          data = List<Object>.from(value.value);
          //print('string type case-------------list:$data');
        } else if (value.value is String) {
          //data = jsonStringToList(value);
          data = List<Object>.from(value.value.split(','));
          //print('list type case-------------list:$data');
        }
        print('*******************STREAM QUERY---------------$column whereIn $data');

        streamBuilder.inFilter(column, data);
        break;
      // case OperType.whereNotIn:
      //   streamBuilder.not(column, "in", value.value);
      //   break;
      // case OperType.textSearch:
      //   streamBuilder.textSearch(column, value.value);
      //   break;
      case OperType.isNull:
        streamBuilder.eq(column, ''); // isNull 함수가 없다. 일단 빈 문자열로 처리한다.
        break;
      default:
        return streamBuilder.eq(column, value.value);
    }
    return streamBuilder;
  }

  @override
  Future<List> queryPage(
    String collectionId, {
    required Map<String, QueryValue> where,
    required Map<String, OrderDirection> orderBy, // 최대 2개 까지만 유효함.
    int? limit,
    int? offset,
    List<Object?>? startAfter, // 사용안됨.
  }) async {
    logger.finest('queryPage');

    await initialize();
    assert(AbsDatabase.sbDBConn != null);
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);

    PostgrestFilterBuilder filterBuilder = fromRef.select();

    where.forEach((key, value) {
      filterBuilder = queryMaker(key, value.operType, value.value, filterBuilder);
    });

    // Map<String, Object> objWhere = {};
    // where.forEach((key, value) {
    //   objWhere[key] = value;
    // });
    if (orderBy.isEmpty) {
      if (limit != null) {
        if (offset != null) {
          return await filterBuilder.limit(limit).range(offset, offset + limit);
        }
        return await filterBuilder.limit(limit);
      }
      return await filterBuilder.select();
    }

    if (orderBy.length == 1) {
      OrderDirection value = orderBy.values.first;
      String key = orderBy.keys.first;

      if (limit != null) {
        if (offset != null) {
          return await filterBuilder
              .order(key, ascending: value == OrderDirection.ascending)
              .limit(limit)
              .range(offset, offset + limit);
        }
        return await filterBuilder
            .order(key, ascending: value == OrderDirection.ascending)
            .limit(limit);
      }
      return await filterBuilder.order(key, ascending: value == OrderDirection.ascending);
    }

    OrderDirection value1 = orderBy.values.first;
    String key1 = orderBy.keys.first;
    OrderDirection value2 = orderBy.values.elementAt(1);
    String key2 = orderBy.keys.elementAt(1);

    if (limit != null) {
      if (offset != null) {
        return await filterBuilder
            .order(key1, ascending: value1 == OrderDirection.ascending)
            .order(key2, ascending: value2 == OrderDirection.ascending)
            .limit(limit)
            .range(offset, offset + limit);
      }
      return await filterBuilder
          .order(key1, ascending: value1 == OrderDirection.ascending)
          .order(key2, ascending: value2 == OrderDirection.ascending)
          .limit(limit);
    }
    return await filterBuilder
        .order(key1, ascending: value1 == OrderDirection.ascending)
        .order(key1, ascending: value1 == OrderDirection.ascending);
  }

  @override
  Future<void> removeData(String collectionId, String mid) async {
    await initialize();

    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);
    await fromRef.delete().eq('mid', mid);
    logger.finest('$mid deleted');
  }

  @override
  dynamic initStream({
    required String collectionId,
    required Map<String, dynamic> where, //dynamic is QueryValue
    required String orderBy,
    bool descending = true,
    int? limit, // 페이지 크기
    bool hasPage = false,
  }) {
    assert(AbsDatabase.sbDBConn != null);
    SupabaseQueryBuilder fromRef = AbsDatabase.sbDBConn!.from(collectionId);

    SupabaseStreamFilterBuilder streamBuilder = fromRef.stream(primaryKey: ['mid']);
    SupabaseStreamBuilder filterBuilder = streamBuilder;
    // where.forEach((key, value) {
    //   filterBuilder = queryMakerStream(key, value, streamBuilder);
    // });

    if (where.isNotEmpty) {
      // where 절을 하나 밖에 처리하지 못하기 때문에, 나머지는  builder 에서 제거한다.
      String key = where.keys.first;
      QueryValue value = where.values.first;

      filterBuilder = queryMakerStream(key, value, streamBuilder);

      if (limit != null) {
        return
            // fromRef
            //     .stream(primaryKey: ['mid'])
            //     .eq(key, value)
            filterBuilder.order(orderBy, ascending: !descending).limit(limit);
      }
      return
          // fromRef
          //     .stream(primaryKey: ['mid'])
          //.eq(key, value)
          filterBuilder.order(orderBy, ascending: !descending);
    }

    // where 조건절이 비어있는 경우.

    if (limit != null) {
      return
          // fromRef
          //     .stream(primaryKey: ['mid'])
          filterBuilder.order(orderBy, ascending: !descending).limit(limit);
    }
    return streamBuilder.order(orderBy, ascending: !descending);
  }

  @override
  Widget streamData2({
    required dynamic snapshot,
    required Widget Function(List<Map<String, dynamic>> resultList) consumerFunc,
    Map<String, dynamic>? where,
    bool hasPage = false,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Text('Loading...');
          default:
            logger.finest('streamData :  ${snapshot.data!.length} data founded');

            // 마지막 문서 업데이트 (페이징을 위해)
            // if (hasPage) {
            //   startAfter = snapshot.data!.isNotEmpty ? snapshot.data!.last : null;
            // }

            return consumerFunc(filterSnapshotData(snapshot.data!, where));
        }
      },
    );
  }

  @override
  Widget streamData({
    required String collectionId,
    required Widget Function(List<Map<String, dynamic>> resultList) consumerFunc,
    required Map<String, dynamic> where,
    required String orderBy,
    bool descending = true,
    int? limit, // 페이지 크기
    bool hasPage = false,
  }) {
    final stream = initStream(collectionId: collectionId, where: where, orderBy: orderBy);
    // Query<Object?> queryRef = fromRef; // Query 타입으로 초기화

    // 여러 조건이 주어진 경우 where 조건을 추가
    // where.forEach((fieldName, fieldValue) {
    //   queryRef = queryRef.where(fieldName, isEqualTo: fieldValue.value);
    // });

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Text('Loading...');
          default:
            logger.finest('streamData :  ${snapshot.data!.length} data founded');

            // // 마지막 문서 업데이트 (페이징을 위해)
            // if (hasPage) {
            //   startAfter = snapshot.data!.isNotEmpty ? snapshot.data!.last : null;
            // }

            return consumerFunc(filterSnapshotData(snapshot.data!, where));
        }
      },
    );
  }

  List<Map<String, dynamic>> filterSnapshotData(
      List<Map<String, dynamic>> snapshotData, Map<String, dynamic>? where) {
    if (where == null || where.length < 2) {
      return snapshotData;
    }

    removeFirstElement(where);

    return snapshotData.where((data) {
      // where 조건에 해당하는 값이 있는지 확인
      for (var key in where.keys) {
        if (!data.containsKey(key) || data[key] != where[key]) {
          return false; // 조건에 맞지 않는 항목은 제외
        }
      }
      return true; // 조건에 맞는 항목만 포함
    }).toList();
  }

  void removeFirstElement(Map<String, dynamic> where) {
    if (where.isNotEmpty) {
      // 키 리스트를 가져옴
      var keys = where.keys.toList();
      // 첫 번째 키를 가져옴
      var firstKey = keys.first;
      // 첫 번째 키를 사용하여 요소를 제거
      where.remove(firstKey);
    }
  }

  List<String> jsonStringToList(String value) {
    if (value.isEmpty) {
      return [];
    }
    try {
      List<dynamic> parsedList = jsonDecode(value);
      // List<dynamic>을 List<String>으로 변환
      List<String> stringList = parsedList.map((item) => item.toString()).toList();
      return stringList;
    } catch (e) {
      logger.severe('invalid json format ($value)');
    }
    return [];
  }
}
