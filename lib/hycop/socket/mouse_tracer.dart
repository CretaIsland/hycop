import 'package:flutter/material.dart';


MouseTracer? mouseTracerHolder;

class MouseTracer extends ChangeNotifier {

  String methodFlag = '';
  String targetUserEmail = '';
  String targetUserName = '';

  List<MouseModel> mouseModelList = [];
  List<Map<String, String>> focusFrameList = [];


  void joinUser(List<dynamic> userList) {
    for(var user in userList) {
      if(mouseModelList.where((element) => element.socketID == user["socketID"]).isEmpty) {
        mouseModelList.add(MouseModel(user["socketID"], user["userID"], user["userName"], 0.0, 0.0));
      }
    }
    methodFlag = 'joinUser';
    targetUserEmail = mouseModelList.last.userID;
    targetUserName = mouseModelList.last.userName;
    notifyListeners();
  }

  void leaveUser(String socketID) {
    MouseModel targetModel = mouseModelList.firstWhere((userCursor) => userCursor.socketID == socketID);
    methodFlag = 'leaveUser';
    targetUserEmail = targetModel.userID;
    targetUserName = targetModel.userName;
    mouseModelList.remove(targetModel);
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
  String socketID = "";
  String userID = "";
  String userName = "";
  double cursorX = 0.0;
  double cursorY = 0.0;

  MouseModel(this.socketID, this.userID, this.userName, this.cursorX, this.cursorY);

  void changePosition(double dx, double dy) {
    cursorX = dx;
    cursorY = dy;
  }
}