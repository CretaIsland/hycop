// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hycop/hycop/utils/hycop_utils.dart';
import 'package:synchronized/synchronized.dart';

import '../../hycop/absModel/abs_ex_model.dart';
import '../../hycop/absModel/abs_ex_model_manager.dart';
import '../util/config.dart';
import '../util/logger.dart';

SaveManager? saveManagerHolder;

//자동 저장 , 변경이 있을 때 마다 저장되게 된다.
class SaveManager extends ChangeNotifier {
  final Lock _datalock = Lock();
  final Lock _dataCreatedlock = Lock();

  final Queue<String> _dataChangedQue = Queue<String>();
  final Queue<AbsExModel> _dataCreatedQue = Queue<AbsExModel>();

  final Map<String, Map<String, AbsExModelManager>> _managerMap = {};

  AbsExModel? _defaultBook;
  final List<String> _bookChildrens = [];

  bool _somethingSaved = false;
  bool isSomethingSaved() {
    if (_somethingSaved == false) return false;
    _somethingSaved = false;
    return true;
  }

  void addBookChildren(String child) {
    _bookChildrens.add(child);
  }

  bool isBookChildren(String mid) {
    for (var ele in _bookChildrens) {
      if (ele == mid.substring(0, 5)) return true;
    }
    return false;
  }

  void setDefaultBook(AbsExModel? book) {
    if (book == null) {
      logger.severe('setDefaultBook() failed');
      return;
    }
    logger.fine('setDefaultBook()');
    _defaultBook = book;
  }

  void registerManager(String className, AbsExModelManager manager, {String postfix = 'onlyOne'}) {
    Map<String, AbsExModelManager>? map = _managerMap[className];
    if (map == null) {
      map = {postfix: manager};
      _managerMap[className] = map;
    } else {
      map[postfix] = manager;
    }
  }

  void unregisterManager(String className, {String postfix = 'onlyOne'}) {
    Map<String, AbsExModelManager>? map = _managerMap[className];
    if (map != null) {
      map.remove(postfix);
    }
    if (map == null || map.isEmpty) {
      _managerMap.remove(className);
    }
  }

  Map<String, AbsExModelManager>? _getManager(String mid) {
    String className = HycopUtils.getClassName(mid);
    logger.fine('_getManager($className)');
    return _managerMap[className];
  }

  Timer? _saveTimer;

  void stopTimer() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  void shouldBookSave(String mid) {
    if (isBookChildren(mid) == true) {
      // book 이 아닌 다른 Row 가 save 된 것인데, 마지막에 Book 의 updateTime 을 한번 바뀌어 줘야 한다.
      if (_defaultBook != null) {
        logger.finest('shouldBookSave');
        _defaultBook!.setUpdateTime();
        _dataChangedQue.add(_defaultBook!.mid);
      }
    }
  }

  Future<void> pushChanged(String mid, String hint, {bool dontChangeBookTime = false}) async {
    await _datalock.synchronized(() async {
      if (!_dataChangedQue.contains(mid)) {
        logger.info('changed:$mid, via $hint');
        _dataChangedQue.add(mid);
        notifyListeners();
        if (dontChangeBookTime == false) {
          logger.finest('shouldBookSave');
          shouldBookSave(mid);
        }
      }
    });
  }

  Future<void> pushCreated(AbsExModel model, String hint) async {
    await _dataCreatedlock.synchronized(() async {
      logger.info('created:${model.mid}, via $hint');
      _dataCreatedQue.add(model);
      notifyListeners();
      shouldBookSave(model.mid);
    });
  }

  Future<void> runSaveTimer() async {
    _saveTimer = Timer.periodic(Duration(milliseconds: myConfig!.config.savePeriod), (timer) async {
      await _datalock.synchronized(() async {
        if (_dataChangedQue.isNotEmpty) {
          while (_dataChangedQue.isNotEmpty) {
            final mid = _dataChangedQue.first;
            // Save here !!!!
            Map<String, AbsExModelManager>? managerMap = _getManager(mid);
            if (managerMap != null) {
              for (AbsExModelManager manager in managerMap.values) {
                manager.setToDBByMid(mid);
                logger.finest('$mid saved');
                _somethingSaved = true;
              }
            }
            _dataChangedQue.removeFirst();
          }
          notifyListeners();
          //logHolder.log('autoSave------------end', level: 5);
        }
      });
      await _dataCreatedlock.synchronized(() async {
        if (_dataCreatedQue.isNotEmpty) {
          logger.finest('autoSaveCreated------------start(${_dataCreatedQue.length})');
          while (_dataCreatedQue.isNotEmpty) {
            final model = _dataCreatedQue.first;
            // Save here !!!!
            // _getManager(model.mid)?.createToDB(model);
            // logger.finest('${model.mid} saved');
            Map<String, AbsExModelManager>? managerMap = _getManager(model.mid);
            if (managerMap != null) {
              for (AbsExModelManager manager in managerMap.values) {
                manager.createToDB(model);
                logger.finest('${model.mid} created');
                _somethingSaved = true;
              }
            }

            _dataCreatedQue.removeFirst();
          }
          notifyListeners();
          logger.finest('autoSaveCreated------------end');
        }
      });
    });
  }
}
