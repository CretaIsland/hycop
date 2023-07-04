import 'package:flutter/material.dart';

MouseTracer? mouseTracerHolder;
class MouseTracer extends ChangeNotifier {

  String methodFlag = '';
  String targetUserEmail = '';
  String targetUserName = '';

  List<MouseModel> userMouseList = [];


  void initialize() {
    methodFlag = '';
    targetUserEmail = '';
    targetUserName = '';
    userMouseList = [];
  }

  void receiveOtherInfo(List<dynamic> userList) {
    for(var user in userList) {
      // 중복 체크
      if(userMouseList.where((element) => element.userId == user['userId']).isEmpty) {
        userMouseList.add(MouseModel(
          user['socketId'], 
          user['userId'], 
          user['userName'], 
          0.0, 
          0.0
        ));
      }
    }
    if(userMouseList.isNotEmpty) {
      methodFlag = 'joinUser';
      targetUserEmail = userMouseList.last.userId;
      targetUserName = userMouseList.last.userName;
    }
    notifyListeners();
  }

  void receiveNewInfo(dynamic newUserInfo) {
    if(userMouseList.where((element) => element.userId == newUserInfo['userId']).isEmpty) {
      userMouseList.add(MouseModel(
        newUserInfo['socketId'], 
        newUserInfo['userId'], 
        newUserInfo['userName'], 
        0.0, 
        0.0
      ));
    }
    methodFlag = 'joinUser';
    targetUserEmail = userMouseList.last.userId;
    targetUserName = userMouseList.last.userName;
    notifyListeners();
  }

  void leaveUser(String socketId) {
    MouseModel leaveUser = userMouseList.firstWhere((userMouse) => userMouse.socketId == socketId);
    methodFlag = 'leaveUser';
    targetUserEmail = leaveUser.userId;
    targetUserName = leaveUser.userName;
    userMouseList.remove(leaveUser);
    notifyListeners();
  }

  void updateCursor(Map<String, dynamic> data) {
    userMouseList[getIndex(data["userId"])].cursorX = data["dx"];
    userMouseList[getIndex(data["userId"])].cursorY = data["dy"];
    notifyListeners();
  }

  int getIndex(String userId) { // 이메일
    return userMouseList.indexWhere((userCursor) => userCursor.userId == userId);
  }

}

class MouseModel {
  String socketId = "";
  String userId = "";
  String userName = "";
  double cursorX = 0.0;
  double cursorY = 0.0;

  MouseModel(this.socketId, this.userId, this.userName, this.cursorX, this.cursorY);

}