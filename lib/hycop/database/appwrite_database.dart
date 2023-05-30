// ignore_for_file: depend_on_referenced_packages
//import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:appwrite/appwrite.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../../hycop/utils/hycop_utils.dart';
import '../../hycop/hycop_factory.dart';
import '../../common/util/logger.dart';
import 'abs_database.dart';
import '../../common/util/config.dart';

class AppwriteDatabase extends AbsDatabase {
  Databases? database;

  @override
  Future<void> initialize() async {
    if (AbsDatabase.awDBConn == null) {
      //logger.finest(
      //    "AppwriteDatabase initialize ${myConfig!.serverConfig!.dbConnInfo.databaseURL}, ${myConfig!.serverConfig!.dbConnInfo.projectId}");
      await HycopFactory.initAll();
      AbsDatabase.setAppWriteApp(Client()
        ..setProject(myConfig!.serverConfig!.dbConnInfo.projectId)
        ..setSelfSigned(status: true)
        ..setEndpoint(myConfig!.serverConfig!.dbConnInfo.databaseURL));
    }
    // ignore: prefer_conditional_assignment
    if (database == null) {
      database = Databases(AbsDatabase.awDBConn!);
    }
  }

  @override
  Future<Map<String, dynamic>> getData(String collectionId, String mid) async {
    // List resultList =
    //     await simpleQueryData(collectionId, name: 'mid', value: mid, orderBy: 'updateTime');
    // return resultList.first;
    await initialize();
    String key = HycopUtils.midToKey(mid);
    try {
      final doc = await database!.getDocument(
        databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
        collectionId: collectionId,
        documentId: key,
      );
      return doc.data;
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return {};
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }

  @override
  Future<List> getAllData(String collectionId) async {
    await initialize();

    try {
      final result = await database!.listDocuments(
          databaseId: myConfig!.serverConfig!.dbConnInfo.appId, collectionId: collectionId);
      return result.documents.map((element) {
        return element.data;
      }).toList();
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return [];
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }

  @override
  Future<void> setData(String collectionId, String mid, Object data) async {
    await initialize();

    try {
      String key = HycopUtils.midToKey(mid);
      logger.finest('setData($key)');
      await database!.updateDocument(
        databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
        collectionId: collectionId,
        documentId: key,
        data: data as Map<String, dynamic>,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return;
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }

  @override
  Future<void> createData(String collectionId, String mid, Map<dynamic, dynamic> data) async {
    await initialize();

    try {
      logger.finest('createData($mid),($collectionId)');
      String key = HycopUtils.midToKey(mid);
      logger.finest('createData($key)');
      await database!.createDocument(
        databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
        collectionId: collectionId,
        documentId: key,
        data: data,
      );
    } on AppwriteException catch (e) {
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
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

    try {
      //String orderType = descending ? 'DESC' : 'ASC';
      final result = await database!.listDocuments(
        databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
        collectionId: collectionId,
        queries: [
          Query.equal(name, value),
          descending ? Query.orderDesc(orderBy) : Query.orderAsc(orderBy)
        ], // index 를 만들어줘야 함.
        //orderAttributes: [orderBy],
        //orderTypes: [orderType],
      );
      return result.documents.map((element) {
        return element.data;
      }).toList();
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return [];
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }

  @override
  Future<List> queryData(
    String collectionId, {
    required Map<String, dynamic> where,
    required String orderBy,
    bool descending = true,
    int? limit,
    int? offset, // appwrite only
    List<Object?>? startAfter, // firebase only
  }) async {
    await initialize();

    try {
      //String orderType = descending ? 'DESC' : 'ASC';

      List<dynamic> queryList = [];
      where.map((mid, value) {
        queryList.add(Query.equal(mid, value));
        return MapEntry(mid, value);
      });

      List<String> additional = [
        descending ? Query.orderDesc(orderBy) : Query.orderAsc(orderBy),
      ];
      if (limit != null) {
        additional.add(Query.limit(limit));
      }
      if (offset != null) {
        additional.add(Query.offset(offset));
      }

      final result = await database!.listDocuments(
          databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
          collectionId: collectionId,
          queries: [
            ...queryList,
            ...additional,
          ] // index 를 만들어줘야 함.
          //orderAttributes: [orderBy],
          //orderTypes: [orderType],
          //limit: limit,
          //offset: offset,
          );
      return result.documents.map((doc) {
        //logger.finest(doc.data.toString());
        return doc.data;
      }).toList();
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return [];
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }

  void queryMaker(String mid, QueryValue value, List<dynamic> queryList) {
    switch (value.operType) {
      case OperType.isEqualTo:
        queryList.add(Query.equal(mid, value.value));
        break;
      case OperType.isGreaterThan:
        queryList.add(Query.greaterThan(mid, value.value));
        break;
      case OperType.isGreaterThanOrEqualTo:
        queryList.add(Query.greaterThanEqual(mid, value.value));
        break;
      case OperType.isLessThan:
        queryList.add(Query.lessThan(mid, value.value));
        break;
      case OperType.isLessThanOrEqualTo:
        queryList.add(Query.lessThanEqual(mid, value.value));
        break;
      case OperType.isNotEqualTo:
        queryList.add(Query.notEqual(mid, value.value));
        break;
      case OperType.arrayContains:
        queryList.add(Query.search(mid, value.value));
        break;
      case OperType.arrayContainsAny: // equal 로 대체
        queryList.add(Query.equal(mid, value.value));
        break;
      case OperType.whereIn: // equal 로 대체
        queryList.add(Query.equal(mid, value.value));
        break;
      case OperType.whereNotIn: // appwrite에서는 해당 쿼리가 없음
        assert(true);
        break;
      case OperType.isNull: // appwrite에서는 해당 쿼리가 없음
        assert(true);
        // 최신버전 appwrite에서는 아래와 같이 처리 가능
        // if (value.value is bool) {
        //   if (value.value == true) {
        //     queryList.add(Query.isNull(mid));
        //   } else {
        //     queryList.add(Query.isNotNull(mid));
        //   }
        // }
        break;
    }
  }

  @override
  Future<List> queryPage(
    String collectionId, {
    required Map<String, QueryValue> where,
    required Map<String, OrderDirection> orderBy,
    int? limit,
    int? offset, // appwrite only
    List<Object?>? startAfter, // firebase only
  }) async {
    await initialize();

    try {
      //String orderType = descending ? 'DESC' : 'ASC';
      List<dynamic> queryList = [];
      where.map((mid, value) {
        queryMaker(mid, value, queryList);
        //queryList.add(Query.equal(mid, value));
        return MapEntry(mid, value);
      });

      // List<String> additional = [
      //   descending ? Query.orderDesc(orderBy) : Query.orderAsc(orderBy),
      // ];
      List<String> additional = [];

      for (var val in orderBy.entries) {
        additional.add((val.value == OrderDirection.descending)
            ? Query.orderDesc(val.key)
            : Query.orderAsc(val.key));
      }

      if (limit != null) {
        additional.add(Query.limit(limit));
      }
      if (offset != null) {
        additional.add(Query.offset(offset));
      }

      final result = await database!.listDocuments(
          databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
          collectionId: collectionId,
          queries: [
            ...queryList,
            ...additional,
          ] // index 를 만들어줘야 함.
          //orderAttributes: [orderBy],
          //orderTypes: [orderType],
          //limit: limit,
          //offset: offset,
          );
      return result.documents.map((doc) {
        //logger.finest(doc.data.toString());
        return doc.data;
      }).toList();
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return [];
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }

  @override
  Future<void> removeData(String collectionId, String mid) async {
    await initialize();
    try {
      String key = HycopUtils.midToKey(mid);
      await database!.deleteDocument(
        databaseId: myConfig!.serverConfig!.dbConnInfo.appId,
        collectionId: collectionId,
        documentId: key,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        logger.finest(e.message!);
        return;
      }
      if (e.message != null) {
        throw HycopException(message: e.message!, code: e.code);
      }
      throw HycopException(message: 'Appwrite error', code: e.code);
    }
  }
}
