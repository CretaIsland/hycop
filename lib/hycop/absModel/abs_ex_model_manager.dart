import 'package:flutter/material.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../../common/util/logger.dart';
import '../absModel/abs_ex_model.dart';
import '../hycop_factory.dart';

abstract class AbsExModelManager extends ChangeNotifier {
  @protected
  final String collectionId;
  AbsExModelManager(this.collectionId);

  AbsExModel newModel(String mid);
  void realTimeCallback(String directive, String userId, Map<String, dynamic> dataMap);

  void notify() => notifyListeners();

  List<AbsExModel> modelList = [];

  String debugText() {
    String retval = '${modelList.length} $collectionId founded\n';
    for (AbsExModel model in modelList) {
      if (model.isRemoved.value == false) {
        retval +=
            '${model.mid.substring(0, 15)}...,time=${model.updateTime},tag=${model.hashTag.value}\n';
      }
    }
    return retval;
  }

  Future<List<AbsExModel>> getListFromDB(String userId) async {
    modelList.clear();
    try {
      Map<String, dynamic> query = {};
      query['creator'] = userId;
      query['isRemoved'] = false;
      List resultList = await HycopFactory.dataBase!.queryData(
        collectionId,
        where: query,
        orderBy: 'updateTime',
        //limit: 2,
        //offset: 1, // appwrite only
        //startAfter: [DateTime.parse('2022-08-04 12:00:01.000')], //firebase only
      );
      return resultList.map((ele) {
        AbsExModel model = newModel(ele['mid'] ?? '');
        model.fromMap(ele);
        modelList.add(model);
        return model;
      }).toList();
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<AbsExModel> getFromDB(String mid) async {
    try {
      AbsExModel model = newModel(mid);
      model.fromMap(await HycopFactory.dataBase!.getData(collectionId, mid));
      return model;
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<List<AbsExModel>> getAllListFromDB() async {
    modelList.clear();
    try {
      Map<String, dynamic> query = {};
      query['isRemoved'] = false;
      List resultList = await HycopFactory.dataBase!.queryData(
        collectionId,
        where: query,
        orderBy: 'updateTime',
        //limit: 2,
        //offset: 1, // appwrite only
        //startAfter: [DateTime.parse('2022-08-04 12:00:01.000')], //firebase only
      );
      return resultList.map((ele) {
        AbsExModel model = newModel(ele['mid'] ?? '');
        model.fromMap(ele);
        modelList.add(model);
        return model;
      }).toList();
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<void> createToDB(AbsExModel model) async {
    try {
      //await HycopFactory.dataBase!.createData(collectionId, model.mid, model.toMap());
      await HycopFactory.dataBase!.createModel(collectionId, model);
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<void> setToDB(AbsExModel model) async {
    try {
      //await HycopFactory.dataBase!.setData(collectionId, model.mid, model.toMap());
      await HycopFactory.dataBase!.setModel(collectionId, model);
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<void> setToDBByMid(String mid) async {
    try {
      //await HycopFactory.dataBase!.setData(collectionId, model.mid, model.toMap());
      AbsExModel? model = getModel(mid);
      if (model != null) {
        await HycopFactory.dataBase!.setModel(collectionId, model);
      } else {
        logger.fine('model not found($collectionId, $mid)');
      }
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<void> removeToDB(String mid) async {
    try {
      //await HycopFactory.dataBase!.removeData(collectionId, mid);
      await HycopFactory.dataBase!.removeModel(collectionId, mid);
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  AbsExModel? getModel(String mid) {
    for (AbsExModel model in modelList) {
      if (model.mid == mid) {
        return model;
      }
    }
    return null;
  }
}
