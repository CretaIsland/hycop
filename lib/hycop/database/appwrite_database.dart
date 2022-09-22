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
      HycopFactory.initAll();
      AbsDatabase.setAppWriteApp(Client()
        ..setProject(myConfig!.serverConfig!.dbConnInfo.projectId)
        ..setSelfSigned(status: true)
        ..setEndpoint(myConfig!.serverConfig!.dbConnInfo.databaseURL));
    }
    // ignore: prefer_conditional_assignment
    if (database == null) {
      database =
          Databases(AbsDatabase.awDBConn!, databaseId: myConfig!.serverConfig!.dbConnInfo.appId);
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
      final result = await database!.listDocuments(collectionId: collectionId);
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
      database!.updateDocument(
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
      logger.finest('createData($mid)');
      String key = HycopUtils.midToKey(mid);
      logger.finest('createData($key)');
      database!.createDocument(
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
      String orderType = descending ? 'DESC' : 'ASC';
      final result = await database!.listDocuments(
        collectionId: collectionId,
        queries: [Query.equal(name, value)], // index 를 만들어줘야 함.
        orderAttributes: [orderBy],
        orderTypes: [orderType],
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
      String orderType = descending ? 'DESC' : 'ASC';

      List<dynamic> queryList = [];
      where.map((mid, value) {
        queryList.add(Query.equal(mid, value));
        return MapEntry(mid, value);
      });

      final result = await database!.listDocuments(
        collectionId: collectionId,
        queries: queryList, // index 를 만들어줘야 함.
        orderAttributes: [orderBy],
        orderTypes: [orderType],
        limit: limit,
        offset: offset,
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
      database!.deleteDocument(
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
