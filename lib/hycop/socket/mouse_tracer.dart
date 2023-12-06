import 'package:flutter/material.dart';

MouseTracer? mouseTracerHolder;

class MouseTracer extends ChangeNotifier {
  String flag = '';
  List<Map<String, String>> targetUsers = []; // email
  List<MouseCursorModel> mouseCursorList = [];

  // 기존에 통신하고 있던 유저 추가
  void addAlreadyConnectUser(List<dynamic> userList) {
    for (Map<String, dynamic> user in userList) {
      if (mouseCursorList.where((element) => element.userId == user["userId"]).isEmpty) {
        mouseCursorList.add(MouseCursorModel(user["socketId"], user["userId"], user["userName"],
            0.0, 0.0, Color(user["cursorColor"])));
        flag = "connectUser";
        targetUsers.add({"userId": user["userId"], "userName": user["userName"]});
      }
    }
    notifyListeners();
  }

  // 새로 통신에 접속한 유저 추가
  void addNewConnectUser(Map<String, dynamic> user) {
    if (mouseCursorList.where((element) => element.userId == user["userId"]).isEmpty) {
      mouseCursorList.add(MouseCursorModel(user["socketId"], user["userId"], user["userName"], 0.0,
          0.0, Color(user["cursorColor"])));
      flag = 'connectUser';
      targetUsers.add({"userId": user["userId"], "userName": user["userName"]});
    }
    notifyListeners();
  }

  // 통신에 끊어진 유저 삭제
  void removeDisConnectUser(String userId, String socketId) {
    int targetIndex = mouseCursorList
        .indexWhere((element) => element.userId == userId && element.socketId == socketId);
    if (targetIndex != -1) {
      flag = 'disconnectUser';
      targetUsers.add({
        "userId": mouseCursorList[targetIndex].userId,
        "userName": mouseCursorList[targetIndex].userName
      });
      mouseCursorList.removeAt(targetIndex);
      notifyListeners();
    }
  }

  // 접속 중인 사용자의 마우스 좌표 업데이트
  void updateCursorPosition(Map<String, dynamic> cursorData) {
    int targetIndex = getTargetIndex(cursorData["userId"]);
    if (targetIndex == -1) return;
    mouseCursorList[targetIndex].x = cursorData["dx"];
    mouseCursorList[targetIndex].y = cursorData["dy"];
    notifyListeners();
  }

  // 사용자의 이메일로 index를 찾아 반환
  int getTargetIndex(String userId) {
    return mouseCursorList.indexWhere((element) => element.userId == userId);
  }

  // mouseTracer destroy
  void destroy({bool notify = true}) {
    //skpark
    mouseCursorList.clear();
    if (notify) {
      notifyListeners();
    }
    //mouseTracerHolder?.dispose();
  }
}

// 마우스 포인터 객체 모델
class MouseCursorModel {
  String socketId = "";
  String userId = "";
  String userName = "";
  double x = 0.0;
  double y = 0.0;
  Color cursorColor = Colors.transparent;

  MouseCursorModel(this.socketId, this.userId, this.userName, this.x, this.y, this.cursorColor);
}
