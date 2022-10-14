import 'package:flutter/material.dart';


MouseTracer? mouseTracerHolder;

class MouseTracer extends ChangeNotifier {

  List<MouseModel> mouseModelList = [];
  List<Map<String, String>> focusFrameList = [];


  void joinUser(List<dynamic> userList) {
    for(var element in userList) {
      mouseModelList.add(MouseModel(element["userID"], 0.0, 0.0));
    }
    notifyListeners();
  }

  void leaveUser(String userID) {
    mouseModelList.removeWhere((userCursor) => userCursor.userID == userID);
    notifyListeners();
  }

  void changePosition(int index, double dx, double dy) {
    mouseModelList[index].cursorX = dx;
    mouseModelList[index].cursorY = dy;
    notifyListeners();
  }

  void focusFrame(String userID, String frameID) {
    focusFrameList.add({"userID" : userID, "frameID" : frameID});
    notifyListeners();
  }

  void unFocusFrame(String userID) {
    focusFrameList.removeWhere((element) => element["userID"] == userID);
    notifyListeners();
  }

  int getIndex(String userID) {
    return mouseModelList.indexWhere((userCursor) => userCursor.userID == userID);
  }
}


class MouseModel {
  String userID = "";
  double cursorX = 0.0;
  double cursorY = 0.0;

  MouseModel(this.userID, this.cursorX, this.cursorY);

  void changePosition(double dx, double dy) {
    cursorX = dx;
    cursorY = dy;
  }
}