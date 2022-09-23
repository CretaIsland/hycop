// ignore_for_file: must_be_immutable

import 'package:hycop/common/util/logger.dart';
import 'package:hycop/common/undo/undo.dart';
import 'package:hycop/hycop/absModel/abs_ex_model.dart';
import 'package:hycop/hycop/enum/model_enums.dart';
import 'app_enums.dart';

// ignore: camel_case_types
class BookModel extends AbsExModel {
  String creator = '';
  late UndoAble<String> name;
  late UndoAble<int> width;
  late UndoAble<int> height;
  late UndoAble<bool> isSilent;
  late UndoAble<bool> isAutoPlay;
  late UndoAble<BookType> bookType;
  late UndoAble<String> description;
  late UndoAble<bool> isReadOnly;
  late UndoAble<String> thumbnailUrl;
  late UndoAble<ContentsType> thumbnailType;
  late UndoAble<double> thumbnailAspectRatio;
  late UndoAble<int> viewCount;

  @override
  List<Object?> get props => [
        ...super.props,
        creator,
        name,
        width,
        height,
        isSilent,
        isAutoPlay,
        bookType,
        description,
        isReadOnly,
        thumbnailUrl,
        thumbnailType,
        thumbnailAspectRatio,
        viewCount
      ];
  BookModel() : super(type: ExModelType.book, parent: '') {
    name = UndoAble<String>('', mid);
    width = UndoAble<int>(0, mid);
    height = UndoAble<int>(0, mid);
    thumbnailUrl = UndoAble<String>('', mid);
    thumbnailType = UndoAble<ContentsType>(ContentsType.none, mid);
    thumbnailAspectRatio = UndoAble<double>(1, mid);
    isSilent = UndoAble<bool>(false, mid);
    isAutoPlay = UndoAble<bool>(false, mid);
    bookType = UndoAble<BookType>(BookType.presentaion, mid);
    isReadOnly = UndoAble<bool>(false, mid);
    viewCount = UndoAble<int>(0, mid);
    description = UndoAble<String>("You could do it simple and plain", mid);
  }

  BookModel.withName(String nameStr, this.creator) : super(type: ExModelType.book, parent: '') {
    name = UndoAble<String>(nameStr, mid);
    width = UndoAble<int>(0, mid);
    height = UndoAble<int>(0, mid);
    thumbnailUrl = UndoAble<String>('', mid);
    thumbnailType = UndoAble<ContentsType>(ContentsType.none, mid);
    thumbnailAspectRatio = UndoAble<double>(1, mid);
    isSilent = UndoAble<bool>(false, mid);
    isAutoPlay = UndoAble<bool>(false, mid);
    bookType = UndoAble<BookType>(BookType.presentaion, mid);
    isReadOnly = UndoAble<bool>(false, mid);
    viewCount = UndoAble<int>(0, mid);
    description = UndoAble<String>("You could do it simple and plain", mid);
  }
  @override
  void copyFrom(AbsExModel src, {String? newMid, String? pMid}) {
    super.copyFrom(src, newMid: newMid, pMid: pMid);
    BookModel srcBook = src as BookModel;
    creator = src.creator;
    name = UndoAble<String>(srcBook.name.value, mid);
    width = UndoAble<int>(srcBook.width.value, mid);
    height = UndoAble<int>(srcBook.height.value, mid);
    thumbnailUrl = UndoAble<String>(srcBook.thumbnailUrl.value, mid);
    thumbnailType = UndoAble<ContentsType>(srcBook.thumbnailType.value, mid);
    thumbnailAspectRatio = UndoAble<double>(srcBook.thumbnailAspectRatio.value, mid);
    isSilent = UndoAble<bool>(srcBook.isSilent.value, mid);
    isAutoPlay = UndoAble<bool>(srcBook.isAutoPlay.value, mid);
    bookType = UndoAble<BookType>(srcBook.bookType.value, mid);
    isReadOnly = UndoAble<bool>(srcBook.isReadOnly.value, mid);
    viewCount = UndoAble<int>(srcBook.viewCount.value, mid);
    description = UndoAble<String>(srcBook.description.value, mid);
    logger.finest('BookCopied($mid)');
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    super.fromMap(map);
    name.set(map["name"] ?? '', save: false, noUndo: true);
    creator = map["creator"] ?? (map["userId"] ?? '');
    width.set(map["width"] ?? 0, save: false, noUndo: true);
    height.set(map["height"] ?? 0, save: false, noUndo: true);
    isSilent.set(map["isSilent"] ?? false, save: false, noUndo: true);
    isAutoPlay.set(map["isAutoPlay"] ?? false, save: false, noUndo: true);
    isReadOnly.set(map["isReadOnly"] ?? (map["readOnly"] ?? false), save: false, noUndo: true);
    bookType.set(BookType.fromInt(map["bookType"] ?? 0), save: false, noUndo: true);
    description.set(map["description"] ?? '', save: false, noUndo: true);
    thumbnailUrl.set(map["thumbnailUrl"] ?? '', save: false, noUndo: true);
    thumbnailType.set(ContentsType.fromInt(map["thumbnailType"] ?? 1), save: false, noUndo: true);
    thumbnailAspectRatio.set((map["thumbnailAspectRatio"] ?? 1), save: false, noUndo: true);
    viewCount.set((map["viewCount"] ?? 0), save: false, noUndo: true);
  }

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addEntries({
        "name": name.value,
        "creator": creator,
        "width": width.value,
        "height": height.value,
        "isSilent": isSilent.value,
        "isAutoPlay": isAutoPlay.value,
        "isReadOnly": isReadOnly.value,
        "bookType": bookType.value.index,
        "description": description.value,
        "thumbnailUrl": thumbnailUrl.value,
        "thumbnailType": thumbnailType.value.index,
        "thumbnailAspectRatio": thumbnailAspectRatio.value,
        "viewCount": viewCount.value,
      }.entries);
  }
}
