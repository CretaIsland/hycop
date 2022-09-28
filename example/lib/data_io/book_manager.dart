import 'package:hycop/hycop/absModel/abs_ex_model.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/absModel/abs_ex_model_manager.dart';
import '../model/book_model.dart';

BookManager? bookManagerHolder;

class BookManager extends AbsExModelManager {
  BookManager() : super('hycop_book');
  @override
  AbsExModel newModel() => BookModel();

  @override
  void realTimeCallback(String directive, String userId, Map<String, dynamic> dataMap) {
    logger.finest('realTimeCallback invoker($directive, $userId)');
    if (directive == 'create') {
      BookModel book = BookModel();
      book.fromMap(dataMap);
      modelList.insert(0, book);
      logger.finest('${book.mid} realtime added');
      notifyListeners();
    } else if (directive == 'set') {
      String mid = dataMap["mid"] ?? '';
      if (mid.isEmpty) {
        return;
      }
      for (AbsExModel model in modelList) {
        if (model.mid == mid) {
          model.fromMap(dataMap);
          logger.finest('${model.mid} realtime changed');
          notifyListeners();
        }
      }
    } else if (directive == 'remove') {
      String mid = dataMap["mid"] ?? '';
      logger.finest('removed mid = $mid');
      if (mid.isEmpty) {
        return;
      }
      for (AbsExModel model in modelList) {
        if (model.mid == mid) {
          modelList.remove(model);
          logger.finest('${model.mid} realtime removed');
          notifyListeners();
        }
      }
    }
  }
}
