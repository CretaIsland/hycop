// ignore_for_file: depend_on_referenced_packages, prefer_final_fields, must_be_immutable

import 'package:uuid/uuid.dart';
// import 'package:equatable/equatable.dart';

//import '../common/util/logger.dart';
//import '../common/undo/save_manager.dart';
//import '../common/undo/undo.dart';
// import '../common/util/config.dart';
// import '../hycop/absModel/app_enums.dart';
// import '../hycop/absModel/abs_ex_model.dart';

enum ObjectType {
  none,
  user,
  //group,
  //,
  end;

  static int validCheck(int val) => (val > end.index || val < none.index) ? none.index : val;
  static ObjectType fromInt(int? val) => ObjectType.values[validCheck(val ?? none.index)];
}

String genMid2(ObjectType type) {
  String mid = '${type.name}=';
  mid += const Uuid().v4();
  return mid;
}

// DateTime dateTimeFromDB(dynamic src) {
//   if (myConfig!.serverType == ServerType.appwrite) {
//     return DateTime.parse(src);
//   }
//   return src.toDate();
// }
//
// dynamic dateTimeToDB(DateTime src) {
//   if (myConfig!.serverType == ServerType.appwrite) {
//     return src.toString();
//   }
//   return src;
// }

class AbsModel {
  Map<String, dynamic> _map = {};
  Map<String, dynamic> get getValueMap => _map;
  dynamic getValue(String key) => _map[key]; // ?? '';
  void setValue(String key, dynamic value) => _map[key] = value;

  ObjectType type;
  late String mid; // => (_map['mid'] ?? '');
  String createTime = ''; // => (_map['createTime'] ?? '');
  String updateTime = ''; // => (_map['createTime'] ?? '');

  //
  // isRemoved attr 추가
  //

  AbsModel({required this.type}) {
    _map['type'] = type.index;
    mid = genMid2(type);
    createTime = DateTime.now().toIso8601String();
    updateTime = DateTime.now().toIso8601String();
  }

  void copyFrom(AbsModel src, {String? newMid}) {
    _map.clear();
    _map.addAll(src.getValueMap);
    _map['mid'] = newMid ?? genMid2(type);
  }

  void copyTo(AbsModel target) {
    target.copyFrom(this, newMid: mid);
  }

  void fromMap(Map<String, dynamic> map) {
    _map.clear();
    mid = map["mid"] ?? genMid2(ObjectType.user);
    _map.addAll(map);
    _map.remove('mid');
    _map.remove('createTime');
    _map.remove('updateTime');
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> retMap = {};
    retMap.addAll(_map);
    retMap['mid'] = mid;
    retMap['createTime'] = createTime;
    retMap['updateTime'] = updateTime;
    return retMap;
  }

  //bool isChanged(AbsExModel other) => !(this == other);

  String debugText() {
    Map<String, dynamic> data = getValueMap;
    String retval = '';
    data.map((key, value) {
      retval += '$key=${value.toString()}\n';
      return MapEntry(key, value);
    });
    return retval;
  }

  void save() {
    //saveManagerHolder?.pushChanged(mid, 'save model');
  }

  void create() {
    //saveManagerHolder!.pushCreated(this, 'create model');
  }
}
