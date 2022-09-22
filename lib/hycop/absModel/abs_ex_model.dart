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
  DateTime get updateTime => _updateTime;

  late UndoAble<String> parentMid;
  late UndoAble<double> order;
  late UndoAble<String> hashTag;
  late UndoAble<bool> isRemoved;

  @override
  List<Object?> get props => [mid, type, parentMid, order, hashTag, isRemoved];

  AbsExModel({required this.type, required String parent}) {
    _mid = HycopUtils.genMid(type);
    parentMid = UndoAble<String>(parent, mid);
    order = UndoAble<double>(0, mid);
    hashTag = UndoAble<String>('', mid);
    isRemoved = UndoAble<bool>(false, mid);
  }

  void copyFrom(AbsExModel src, {String? newMid, String? pMid}) {
    _mid = newMid ?? HycopUtils.genMid(type);
    parentMid = UndoAble<String>(pMid ?? src.parentMid.value, mid);
    order = UndoAble<double>(src.order.value, mid);
    hashTag = UndoAble<String>(src.hashTag.value, mid);
    isRemoved = UndoAble<bool>(src.isRemoved.value, mid);
    autoSave = src.autoSave;
  }

  void copyTo(AbsExModel target) {
    target.copyFrom(this, newMid: mid, pMid: parentMid.value);
  }

  void fromMap(Map<String, dynamic> map) {
    _mid = map["mid"];
    _updateTime = HycopUtils.dateTimeFromDB(map["updateTime"]);
    parentMid.set(map["parentMid"] ?? '', save: false, noUndo: true);
    order.set(map["order"] ?? 0, save: false, noUndo: true);
    hashTag.set(map["hashTag"] ?? '', save: false, noUndo: true);
    isRemoved.set(map["isRemoved"] ?? false, save: false, noUndo: true);
  }

  Map<String, dynamic> toMap() {
    return {
      //"type": type.index,
      "mid": mid,
      "updateTime": HycopUtils.dateTimeToDB(updateTime),
      "parentMid": parentMid.value,
      "order": order.value,
      "hashTag": hashTag.value,
      "isRemoved": isRemoved.value,
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
