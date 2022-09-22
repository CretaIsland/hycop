// ignore_for_file: depend_on_referenced_packages

import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../hycop/utils/hycop_exceptions.dart';
import '../../common/util/logger.dart';
import '../../hycop/absModel/abs_ex_model.dart';
import '../hycop_factory.dart';

abstract class AbsDatabase {
  //connection info
  static Client? _awDBConn; //appwrite only
  static FirebaseApp? _fbDBApp; // firebase only Database connection

  static Client? get awDBConn => _awDBConn;
  static FirebaseApp? get fbDBApp => _fbDBApp;

  @protected
  static void setAppWriteApp(Client client) => _awDBConn = client;
  @protected
  static void setFirebaseApp(FirebaseApp fb) => _fbDBApp = fb;

  Future<void> initialize();

  Future<Map<String, dynamic>> getData(String collectionId, String mid);
  Future<List> getAllData(String collectionId);
  Future<List> simpleQueryData(String collectionId,
      {required String name,
      required String value,
      required String orderBy,
      bool descending = true,
      int? limit,
      int? offset});

  Future<List> queryData(String collectionId,
      {required Map<String, dynamic> where,
      required String orderBy,
      bool descending = true,
      int? limit,
      int? offset, // appwrite only
      List<Object?>? startAfter}); // firebase onlu

  Future<void> setData(String collectionId, String mid, Map<dynamic, dynamic> data);
  Future<void> createData(String collectionId, String mid, Map<dynamic, dynamic> data);
  Future<void> removeData(String collectionId, String mid);

  Future<void> setModel(String collectionId, AbsExModel model) async {
    try {
      await setData(collectionId, model.mid, model.toMap());
      // Delta 를 저장한다.
      HycopFactory.realtime!.setDelta(directive: 'set', mid: model.mid, delta: model.toMap());
    } catch (e) {
      logger.severe("setModel(set) error", e);
      throw HycopException(message: "setModel(set) error", exception: e as Exception);
    }
  }

  Future<void> createModel(String collectionId, AbsExModel model) async {
    try {
      logger.finest('createModel(${model.mid})');
      await createData(collectionId, model.mid, model.toMap());
      // Delta 를 저장한다.
      HycopFactory.realtime!.setDelta(directive: 'create', mid: model.mid, delta: model.toMap());
    } catch (e) {
      logger.severe("setModel(create) error", e);
      throw HycopException(message: "setModel(create) error", exception: e as Exception);
    }
  }

  Future<void> removeModel(String collectionId, String mid) async {
    try {
      await removeData(collectionId, mid);
      // Delta 를 저장한다.
      Map<String, dynamic> delta = {};
      delta['mid'] = mid;
      HycopFactory.realtime!.setDelta(directive: 'remove', mid: mid, delta: delta);
    } catch (e) {
      logger.severe("setModel(remove) error", e);
      throw HycopException(message: "setModel(remove) error", exception: e as Exception);
    }
  }
}
