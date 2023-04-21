// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../common/util/logger.dart';
import '../../common/util/config.dart';
import '../hycop_factory.dart';
import 'abs_database.dart';

class FirebaseDatabase extends AbsDatabase {
  FirebaseFirestore? _db;

  @override
  Future<void> initialize() async {
    if (AbsDatabase.fbDBApp == null) {
      await HycopFactory.initAll();
      logger.finest('initialize');
      AbsDatabase.setFirebaseApp(await Firebase.initializeApp(
          name: 'database',
          options: FirebaseOptions(
              apiKey: myConfig!.serverConfig!.dbConnInfo.apiKey,
              appId: myConfig!.serverConfig!.dbConnInfo.appId,
              storageBucket: myConfig!.serverConfig!.dbConnInfo.storageBucket,
              messagingSenderId: myConfig!.serverConfig!.dbConnInfo.messagingSenderId,
              projectId: myConfig!.serverConfig!.dbConnInfo.projectId)));

      //_db = null;
    }
    // ignore: prefer_conditional_assignment
    if (_db == null) {
      logger.finest('_db init');
      _db = FirebaseFirestore.instanceFor(app: AbsDatabase.fbDBApp!);
    }
    assert(_db != null);
  }

  @override
  Future<Map<String, dynamic>> getData(String collectionId, String mid) async {
    await initialize();

    CollectionReference collectionRef = _db!.collection(collectionId);

    DocumentSnapshot<Object?> result = await collectionRef.doc(mid).get();
    return result.data() as Map<String, dynamic>;
  }

  @override
  Future<List> getAllData(String collectionId) async {
    await initialize();

    final List resultList = [];
    CollectionReference collectionRef = _db!.collection(collectionId);
    await collectionRef.get().then((snapshot) {
      for (var result in snapshot.docs) {
        resultList.add(result);
      }
    });
    return resultList;
  }

  @override
  Future<void> setData(String collectionId, String mid, Map<dynamic, dynamic> data) async {
    await initialize();

    Map<String, Object?> converted = {};
    for (MapEntry e in data.entries) {
      if (e.value is List) {
        converted[e.key.toString()] = FieldValue.arrayUnion(e.value);
      } else {
        converted[e.key.toString()] = e.value as Object?;
      }
    }
    CollectionReference collectionRef = _db!.collection(collectionId);
    await collectionRef.doc(mid).update(converted);
    // for (MapEntry e in data.entries) {
    //   if (e.value is List) {
    //     await collectionRef.doc(mid).update({e.key.toString(): FieldValue.arrayUnion(e.value)});
    //   }
    // }
    logger.finest('$mid saved');
  }

  @override
  Future<void> createData(String collectionId, String mid, Map<dynamic, dynamic> data) async {
    await initialize();

    logger.finest('createData... $mid!');
    CollectionReference collectionRef = _db!.collection(collectionId);
    await collectionRef.doc(mid).set(data, SetOptions(merge: false));
    for (MapEntry e in data.entries) {
      if (e.value is List) {
        await collectionRef.doc(mid).update({e.key.toString(): FieldValue.arrayUnion(e.value)});
      }
    }

    //await collectionRef.add(data);
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

    final List resultList = [];
    CollectionReference collectionRef = _db!.collection(collectionId);
    await collectionRef
        .orderBy(orderBy, descending: true)
        .where(name, isEqualTo: value)
        .get()
        .then((snapshot) {
      for (var result in snapshot.docs) {
        resultList.add(result);
      }
    });
    return resultList;
  }

  @override
  Future<List> queryData(String collectionId,
      {required Map<String, dynamic> where,
      required String orderBy,
      bool descending = true,
      int? limit,
      int? offset,
      List<Object?>? startAfter}) async {
    logger.finest('before');
    await initialize();
    logger.finest('after');
    assert(_db != null);
    CollectionReference collectionRef = _db!.collection(collectionId);
    Query<Object?> query = collectionRef.orderBy(orderBy, descending: descending);
    where.map((mid, value) {
      query = query.where(mid, isEqualTo: value);
      return MapEntry(mid, value);
    });

    if (limit != null) query = query.limit(limit);
    if (startAfter != null && startAfter.isNotEmpty) query = query.startAfter(startAfter);

    return await query.get().then((snapshot) {
      return snapshot.docs.map((doc) {
        //logger.finest(doc.data()!.toString());
        return doc.data()! as Map<String, dynamic>;
      }).toList();
    });
  }

  Query<Object?> queryMaker(String mid, QueryValue value, Query<Object?> query) {
    switch (value.operType) {
      case OperType.isEqualTo:
        return query.where(mid, isEqualTo: value.value);
      case OperType.isGreaterThan:
        return query.where(mid, isGreaterThan: value.value);
      case OperType.isGreaterThanOrEqualTo:
        return query.where(mid, isGreaterThanOrEqualTo: value.value);
      case OperType.isLessThan:
        return query.where(mid, isLessThan: value.value);
      case OperType.isLessThanOrEqualTo:
        return query.where(mid, isLessThanOrEqualTo: value.value);
      case OperType.isNotEqualTo:
        return query.where(mid, isNotEqualTo: value.value);
      case OperType.arrayContains:
        logger.finest('query=mid arrayContains ${value.value}');
        return query.where(mid, arrayContains: value.value);
      case OperType.arrayContainsAny:
        logger.finest('query=mid arrayContainsAny ${value.value}');
        return query.where(mid, arrayContainsAny: value.value);
    }
  }

  @override
  Future<List> queryPage(String collectionId,
      {required Map<String, QueryValue> where,
      required Map<String, OrderDirection> orderBy,
      int? limit,
      int? offset,
      List<Object?>? startAfter}) async {
    logger.finest('queryPage');
    await initialize();
    assert(_db != null);
    CollectionReference collectionRef = _db!.collection(collectionId);
    Query<Object?> query = collectionRef;
    //Query<Object?> query = collectionRef.orderBy(orderBy, descending: descending);

    //for (var val in orderBy.entries) {
    orderBy.map((key, value) {
      query = query.orderBy(key, descending: (value == OrderDirection.descending));
      logger.finest('order by $key');
      return MapEntry(key, value);
    });

    where.map((mid, value) {
      //query = query.where(mid, isEqualTo: value);
      query = queryMaker(mid, value, query);
      return MapEntry(mid, value);
    });

    if (limit != null) query = query.limit(limit);
    if (startAfter != null && startAfter.isNotEmpty) query = query.startAfter(startAfter);

    return await query.get().then((snapshot) {
      if (snapshot.docs.isEmpty) {
        logger.finest('no data founded');
        return [];
      }
      return snapshot.docs.map((doc) {
        //logger.finest(doc.data()!.toString());
        return doc.data()! as Map<String, dynamic>;
      }).toList();
    }, onError: (trace) {
      logger.severe("------------DATABASE ERROR -----------");
      logger.severe(trace.toString());
      return [];
    });
  }

  @override
  Future<void> removeData(String collectionId, String mid) async {
    await initialize();

    CollectionReference collectionRef = _db!.collection(collectionId);
    await collectionRef.doc(mid).delete();
    logger.finest('$mid deleted');

    //FirebaseFirestore.instanceFor(app: app)
  }
}
