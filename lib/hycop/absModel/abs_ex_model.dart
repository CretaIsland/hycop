// ignore_for_file: depend_on_referenced_packages, prefer_final_fields, must_be_immutable

import 'package:equatable/equatable.dart';

//import '../common/util/logger.dart';
import '../../common/undo/save_manager.dart';
import '../../common/undo/undo.dart';
import '../../hycop/utils/hycop_utils.dart';
import '../enum/model_enums.dart';

class AbsExModel extends Equatable {
  bool autoSave = true;

  final ExModelType type;
  late String _mid;
  String get mid => _mid;
  DateTime _updateTime = DateTime.now();
  DateTime _createTime = DateTime.now();
  DateTime get updateTime => _updateTime;
  DateTime get createTime => _createTime;

  void setUpdateTime() {
    _updateTime = DateTime.now();
  }

  late UndoAble<String> parentMid;
  late UndoAble<double> order;
  late UndoAble<String> hashTag;
  late UndoAble<bool> isRemoved;
  String _realTimeKey = '';
  String get realTimeKey => _realTimeKey;
  void setRealTimeKey(String key) {
    _realTimeKey = key;
  }

  @override
  List<Object?> get props => [mid, type, parentMid, order, hashTag, isRemoved, realTimeKey];

  AbsExModel({String? pmid, required this.type, required String parent, String? realTimeKey}) {
    if (pmid == null || pmid.isEmpty) {
      _mid = HycopUtils.genMid(type);
    } else {
      _mid = pmid;
    }
    parentMid = UndoAble<String>(parent, mid, 'parentMid');
    order = UndoAble<double>(1, mid, 'order');
    hashTag = UndoAble<String>('', mid, 'hashTag');
    isRemoved = UndoAble<bool>(false, mid, 'isRemoved');
    _realTimeKey = realTimeKey ?? '';
  }

  void copyFrom(AbsExModel src, {String? newMid, String? pMid}) {
    _mid = newMid ?? HycopUtils.genMid(type);
    parentMid = UndoAble<String>(pMid ?? src.parentMid.value, mid, 'parentMid');
    order = UndoAble<double>(src.order.value, mid, 'order');
    hashTag = UndoAble<String>(src.hashTag.value, mid, 'hashTag');
    isRemoved = UndoAble<bool>(src.isRemoved.value, mid, 'isRemoved');
    _realTimeKey = src.realTimeKey;
    autoSave = src.autoSave;
  }

  void updateFrom(AbsExModel src) {
    parentMid.init(src.parentMid.value);
    order.init(src.order.value);
    hashTag.init(src.hashTag.value);
    isRemoved.init(src.isRemoved.value);
    autoSave = src.autoSave;
    _realTimeKey = src.realTimeKey;
  }

  void copyTo(AbsExModel target) {
    target.copyFrom(this, newMid: mid, pMid: parentMid.value);
  }

  void fromMap(Map<String, dynamic> map) {
    _mid = map["mid"] ?? HycopUtils.genMid(type);
    _updateTime =
        map["updateTime"] == null ? DateTime.now() : HycopUtils.dateTimeFromDB(map["updateTime"]);
    _createTime =
        map["createTime"] == null ? _updateTime : HycopUtils.dateTimeFromDB(map["createTime"]);

    //print("createTime = $createTime, $mid");
    parentMid.setDD(map["parentMid"] ?? '', save: false, noUndo: true);
    order.setDD(map["order"] ?? 1, save: false, noUndo: true);
    hashTag.setDD(map["hashTag"] ?? '', save: false, noUndo: true);
    isRemoved.setDD(map["isRemoved"] ?? false, save: false, noUndo: true);
    String? rtKey = map["realTimeKey"];
    if (rtKey != null && rtKey.isNotEmpty) _realTimeKey = rtKey;
  }

  Map<String, dynamic> toMap() {
    return {
      //"type": type.index,
      "mid": mid,
      "updateTime": HycopUtils.dateTimeToDB(updateTime),
      "createTime": HycopUtils.dateTimeToDB(createTime),
      "parentMid": parentMid.value,
      "order": order.value,
      "hashTag": hashTag.value,
      "isRemoved": isRemoved.value,
      "realTimeKey": realTimeKey,
    };
  }

  bool isChanged(AbsExModel other) => !(this == other);

  String debugText() {
    Map<String, dynamic> data = toMap();
    String retval = '';
    data.map((key, value) {
      retval += '$key=${value.toString()}\n';
      return MapEntry(key, value);
    });
    return retval;
  }

  void save() {
    _updateTime = DateTime.now();
    saveManagerHolder?.pushChanged(mid, 'save model');
  }

  void create() {
    saveManagerHolder!.pushCreated(this, 'create model');
  }
}
