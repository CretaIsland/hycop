import 'dart:core';
import 'dart:collection';
import '../util/logger.dart';
import 'save_manager.dart';

enum TransState {
  none,
  start,
  ing,
  end,
}

MyChangeStack mychangeStack = MyChangeStack();

class UndoAble<T> {
  late T _value;
  late String _mid;
  String? hint;

  UndoAble(T val, String m, String? h) {
    _value = val;
    _mid = m;
    hint = h;
  }

  T get value => _value;

  void changeMid(String mid) {
    _mid = mid;
  }

  void printMid() {
    logger.finest('value mid = $_mid');
  }

  void setDD(T val,
      {bool save = true,
      bool noUndo = false,
      bool dontChangeBookTime = false,
      void Function(T val)? doComplete,
      void Function(T val)? undoComplete}) {
    // set Dont Delta 라는 뜻, Delta 를 저장하지 않는  set
    set(
      val,
      save: save,
      noUndo: noUndo,
      dontChangeBookTime: dontChangeBookTime,
      dontRealTime: true,
      doComplete: doComplete,
      undoComplete: undoComplete,
    );
  }

  void set(T val,
      {bool save = true,
      bool noUndo = false,
      bool dontChangeBookTime = false,
      bool dontRealTime = false,
      void Function(T val)? doComplete,
      void Function(T val)? undoComplete}) {
    if (val == _value) return; // 값이 동일하다면, 할 필요가 없다.

    if (noUndo) {
      _value = val;
      if (save && saveManagerHolder != null && _mid.isNotEmpty) {
        //print('noUndo pushChanged $hint');
        saveManagerHolder!.pushChanged(
          _mid,
          'execute $hint',
          dontChangeBookTime: dontChangeBookTime,
          dontRealTime: dontRealTime,
        );
      }
      return;
    }

    MyChange<T> c = MyChange<T>(_value, mid: _mid, execute: () {
      _value = val;
      //print('new MyChange $_value, $_mid');

      if (save && saveManagerHolder != null && _mid.isNotEmpty) {
        //print('pushChanged $hint $_mid');
        saveManagerHolder!
            .pushChanged(_mid, 'execute $hint', dontChangeBookTime: dontChangeBookTime);
      }
    }, redo: () {
      //print('redo old=$val, new=$_value');
      _value = val;
      if (save && saveManagerHolder != null && _mid.isNotEmpty) {
        saveManagerHolder!.pushChanged(_mid, 'redo $hint', dontChangeBookTime: dontChangeBookTime);
      }
      doComplete?.call(_value);
    }, undo: (T old) {
      if (old == _value) return; // 값이 동일하다면, 할 필요가 없다.
      _value = old;
      //print('undo old=$old, new=$_value,_mid=$_mid, save=$save,');
      if (save && saveManagerHolder != null && _mid.isNotEmpty) {
        saveManagerHolder!.pushChanged(_mid, 'undo $hint', dontChangeBookTime: dontChangeBookTime);
      }
      undoComplete?.call(_value);
    });

    mychangeStack.add(c);
  }

  // this function doesn't support undo
  void init(T val) {
    _value = val;
  }
}

// class UndoMonitorAble<T> extends UndoAble<T> {
//   UndoMonitorAble(T val) : super(val);

//   @override
//   void set(T val) {
//     MyChange<T> c = MyChange<T>(_value, () {
//       _value = val;
//     }, (T old) {
//       _value = old;
//     });
//     c.monitored = true;
//     mychangeStack.add(c);
//   }
// }

// class UndoAbleList<T> {
//   late List<T> _value;

//   UndoAbleList(List<T> val) {
//     _value = val;
//   }

//   List<T> get value => _value;

//   void set(List<T> val) {
//     MyChange<List<T>> c = MyChange<List<T>>(_value, () {
//       _value = val;
//     }, (List<T> old) {
//       _value = old;
//     });
//     mychangeStack.add(c);
//   }

//   void add(T val) {
//     MyChange<List<T>> c = MyChange<List<T>>(_value, () {
//       _value.add(val);
//     }, (List<T> old) {
//       _value.remove(val);
//     });
//     mychangeStack.add(c);
//   }

//   void remove(T val) {
//     MyChange<List<T>> c = MyChange<List<T>>(_value, () {
//       _value.remove(val);
//     }, (List<T> old) {
//       _value.add(val);
//     });
//     mychangeStack.add(c);
//   }

//   T removeAt(int index) {
//     T? retval;
//     MyChange<List<T>> c = MyChange<List<T>>(_value, () {
//       retval = _value.removeAt(index);
//     }, (List<T> old) {
//       _value = List.from(old);
//     });
//     mychangeStack.add(c);
//     return retval!;
//   }

//   void insert(int index, T val) {
//     MyChange<List<T>> c = MyChange<List<T>>(_value, () {
//       _value.insert(index, val);
//     }, (List<T> old) {
//       _value = List.from(old);
//     });
//     mychangeStack.add(c);
//   }
// }

// class UndoAbleMap<String, T> {
//   late Map<String, T> _value;

//   UndoAbleMap(Map<String, T> val) {
//     _value = Map.from(val);
//   }

//   Map<String, T> get value => _value;

//   void set(Map<String, T> val) {
//     MyChange<Map<String, T>> c = MyChange<Map<String, T>>(_value, () {
//       _value = Map.from(val);
//     }, (Map<String, T> old) {
//       _value = Map.from(old);
//     });
//     mychangeStack.add(c);
//   }

//   void add(String key, T val) {
//     MyChange<Map<String, T>> c = MyChange<Map<String, T>>(_value, () {
//       _value[key] = val;
//     }, (Map<String, T> old) {
//       //_value = Map.from(old);
//       if (old[key] != null) {
//         _value[key] = old[key]!;
//       } else {
//         _value.remove(key);
//       }
//     });
//     mychangeStack.add(c);
//   }

//   void remove(String key) {
//     MyChange<Map<String, T>> c = MyChange<Map<String, T>>(_value, () {
//       _value.remove(key);
//     }, (Map<String, T> old) {
//       if (old[key] != null) {
//         _value[key] = old[key]!;
//       }
//     });
//     mychangeStack.add(c);
//   }
// }

class MyChangeStack {
  /// Changes to keep track of
  MyChangeStack({this.limit});

  /// Limit changes to store in the history
  int? limit;

  final Queue<MyChange> _history = ListQueue();
  final Queue<MyChange> _redos = ListQueue();

  TransState transState = TransState.none;

  //MyChange? lastChanged;

  /// Can redo the previous change
  bool get canRedo => _redos.isNotEmpty;

  /// Can undo the previous change
  bool get canUndo => _history.isNotEmpty;

  /// Add New Change and Clear Redo Stack
  void add<T>(MyChange<T> change) {
    change.transState = transState;
    if (transState == TransState.start) {
      transState = TransState.ing;
    }
    change.execute();
    _history.addLast(change);
    _moveForward();
  }

  void _moveForward() {
    _redos.clear();

    if (limit != null && _history.length > limit! + 1) {
      _history.removeFirst();
    }
  }

  /// Add New Group of Changes and Clear Redo Stack
  // void addGroup<T>(List<Change<T>> changes) {
  //   _applyChanges(changes);
  //   _history.addLast(changes);
  //   _moveForward();
  // }

  // void _applyChanges(MyChange change) {
  //   change.execute();
  // }

  /// Clear Undo History
  void clear() => clearHistory();

  /// Clear Undo History
  void clearHistory() {
    _history.clear();
    _redos.clear();
  }

  /// Redo Previous Undo
  void redo() {
    int count = 0;
    while (true) {
      if (canRedo == false) {
        break;
      }
      final change = _redos.removeFirst();
      change.redoExecute();
      _history.addLast(change);
      //lastChanged = change;
      count++;
      if (change.transState == TransState.none || change.transState == TransState.end) {
        if (count > 1 && change.mid.isNotEmpty) {
          //print('redo endTrans call save ----------------------');
          saveManagerHolder!.pushChanged(change.mid, 'redo endTrans');
        }
        break;
      }
    }
  }

  /// Undo Last Change
  void undo() {
    int count = 0;
    while (true) {
      //print('TransState=$canUndo');
      if (canUndo == false) {
        break;
      }
      count++;
      final change = _history.removeLast();
      //print('TransState=${change.transState}');
      change.undoExecute();
      _redos.addFirst(change);
      //lastChanged = change;
      if (change.transState == TransState.none || change.transState == TransState.start) {
        if (count > 1 && change.mid.isNotEmpty) {
          //print('undo endTrans call save ----------------------');
          saveManagerHolder!.pushChanged(change.mid, 'undo endTrans');
        }
        break;
      }
    }
  }

  void startTrans() {
    transState = TransState.start;
  }

  void endTrans() {
    if (canUndo) {
      if (_history.last.transState != TransState.start) {
        _history.last.transState = TransState.end;
      }
    }
    transState = TransState.none;
  }
}

class MyChange<T> {
  MyChange(
    this._oldValue, {
    required this.execute(),
    required this.redo(),
    required this.undo(T oldValue),
    this.monitored = false,
    this.transState = TransState.none,
    this.mid = '',
  });

  // MyChange.withContext(
  //   this._oldValue,
  //   this.context, {
  //   required this.execute(),
  //   required this.redo(),
  //   required this.undo(T oldValue),
  //   this.monitored = false,
  //   this.transState = TransState.none,
  // });

  TransState transState = TransState.none;
  bool monitored = false;

  final T _oldValue;
  //BuildContext? context;
  final String mid;

  final void Function() execute;
  final void Function() redo;
  final void Function(T oldValue) undo;

  void redoExecute() {
    redo();
    if (monitored) {}
  }

  void undoExecute() {
    undo(_oldValue);
    if (monitored) {}
  }
}
