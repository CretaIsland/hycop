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
  void realTimeCallback(
      String listenerId, String directive, String userId, Map<String, dynamic> dataMap);

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
      if (resultList.isEmpty) return [];
      return resultList.map((ele) {
        AbsExModel model = newModel(ele['mid'] ?? '');
        model.fromMap(ele);
        modelList.add(model);
        return model;
      }).toList();
    } catch (e) {
      logger.severe('databaseError $e');
      //throw HycopException(message: 'databaseError', exception: e as Exception);
      return [];
    }
  }

  Future<AbsExModel?> getFromDB(String mid) async {
    try {
      AbsExModel model = newModel(mid);
      Map<String, dynamic> data = await HycopFactory.dataBase!.getData(collectionId, mid);
      if (data.isEmpty) {
        logger.warning('data not found $mid');
        return null;
      }
      model.fromMap(data);
      return model;
    } catch (e) {
      logger.severe('databaseError $e');
      //throw HycopException(message: 'databaseError', exception: e as Exception);
      return null;
    }
  }

  Future<bool> isNameExist(String value, {String name = 'name'}) async {
    try {
      return await HycopFactory.dataBase!.isNameExist(collectionId, value: value, name: name);
    } catch (e) {
      logger.severe('databaseError $e');
      //throw HycopException(message: 'databaseError', exception: e as Exception);
    }
    return false;
  }

  Future<String> makeCopyName(String newName) async {
    if (await isNameExist(newName) == false) {
      return newName;
    }
    int count = 0;
    String retval = '';
    while (true) {
      count++;
      retval = '$newName($count)';
      if (await isNameExist(retval) == false) {
        return retval;
      }
      if (count > 100) {
        // 같은 이름이 너무 많다. 그냥 마지막 이름을 쓴다.
        break;
      }
    }
    return retval;
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
      if (resultList.isEmpty) return [];
      return resultList.map((ele) {
        AbsExModel model = newModel(ele['mid'] ?? '');
        model.fromMap(ele);
        modelList.add(model);
        return model;
      }).toList();
    } catch (e) {
      logger.severe('databaseError $e');
      //throw HycopException(message: 'databaseError', exception: e as Exception);
      return [];
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

  Future<void> setToDB(AbsExModel model, {bool dontRealTime = false}) async {
    try {
      //await HycopFactory.dataBase!.setData(collectionId, model.mid, model.toMap());
      await HycopFactory.dataBase!.setModel(collectionId, model, dontRealTime: dontRealTime);
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<void> updateToDB(String mid, Map<String, dynamic> updateDataMap) async {
    try {
      //await HycopFactory.dataBase!.setData(collectionId, model.mid, model.toMap());
      await HycopFactory.dataBase!.updateData(collectionId, mid, updateDataMap);
    } catch (e) {
      logger.severe('databaseError', e);
      throw HycopException(message: 'databaseError', exception: e as Exception);
    }
  }

  Future<void> setToDBByMid(String mid, {bool dontRealTime = false}) async {
    try {
      //print('setToDBByMid()');
      //await HycopFactory.dataBase!.setData(collectionId, model.mid, model.toMap());
      AbsExModel? model = getModel(mid);

      if (model != null) {
        await HycopFactory.dataBase!.setModel(collectionId, model, dontRealTime: dontRealTime);
      } else {
        logger.finest('model not found($collectionId, $mid) in this manager');
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

  dynamic initStream({
    required Map<String, dynamic> where,
    required String orderBy,
    bool descending = true,
    int? limit, // 페이지 크기
  }) {
    return HycopFactory.dataBase!.initStream(
      collectionId: collectionId,
      where: where,
      orderBy: orderBy,
      descending: descending,
      limit: limit,
    );
  }

  Widget streamData2({
    required dynamic snapshot,
    required Widget Function(List<Map<String, dynamic>> resultList) consumerFunc,
  }) {
    return HycopFactory.dataBase!.streamData2(
      snapshot: snapshot,
      consumerFunc: (List<Map<String, dynamic>> resultList) {
        modelList.clear();
        for (Map<String, dynamic> ele in resultList) {
          AbsExModel model = newModel(ele['mid'] ?? '');
          model.fromMap(ele);
          modelList.add(model);
        }
        //notifyListeners();
        return consumerFunc(resultList);
      },
    );
  }

  Widget streamData({
    required Widget Function(List<Map<String, dynamic>> resultList) consumerFunc,
    required Map<String, dynamic> where,
    required String orderBy,
    bool descending = true,
    int? limit, // 페이지 크기
  }) {
    return HycopFactory.dataBase!.streamData(
      collectionId: collectionId,
      consumerFunc: (List<Map<String, dynamic>> resultList) {
        modelList.clear();
        for (Map<String, dynamic> ele in resultList) {
          AbsExModel model = newModel(ele['mid'] ?? '');
          model.fromMap(ele);
          modelList.add(model);
        }
        //notifyListeners();
        return consumerFunc(resultList);
      },
      where: where,
      orderBy: orderBy,
      descending: descending,
      limit: limit,
    );
  }
}
