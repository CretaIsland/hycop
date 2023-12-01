import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/socket/mouse_tracer.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketClient {

  late Socket socket;
  late String roomId;
  Timer? healthCheckTimer;


  void initialize(String socketServerUrl) {
    try {
      socket = io(
        socketServerUrl,
        //'ws://localhost:4432',
        <String, dynamic> {
          "transports": ["websocket"],
          "autoConnect": false
        }
      );
    } catch (error) {
      logger.severe("error during initialize socket server >>> $error");
    }
  }

  Future<void> connectServer(String socketRoomId) async {
    try {
      roomId = socketRoomId;
      socket.connect().onError((error) => logger.severe("error during connect socket server >>> $error"));

      // socket connect event
      socket.on("connect", (data) {
        // 소켓 통신에 참여 가능한지 여부 체크
        socket.emit("checkConnectability", {
          "roomId": roomId,
          "userId": AccountManager.currentLoginUser.email
        });
      }); 
      // socket disconnect event
      socket.on("disconnect", (data) {
        disconnect();
      });


      // ====================================== socket event ======================================
      // 소켓 통신에 참여가 가능하다면
      socket.on("connectable", (data) {
        socket.emit("connectRoom", {
          "roomId": roomId,
          "userId": AccountManager.currentLoginUser.email,
          "userName": AccountManager.currentLoginUser.name,
          "cursorColor": getRandomColor()
        });
      }); 

      // 소켓 통신에 참여가 불가능하다면
      socket.on("unconnectable", (data) {
        disconnect();
      }); 

      // 기존에 통신하고 있던 유저의 데이터 수신
      socket.on("alreadyConnectUser", (data) {
        mouseTracerHolder!.addAlreadyConnectUser(data["userList"]);
      });

      // 새로 통신에 접속한 유저의 데이터 수신
      socket.on("newConnectUser", (data) {
        mouseTracerHolder!.addNewConnectUser(data);
      });

      // 접속을 끊은 유저의 데이터 수신
      socket.on("disconnectUser", (data) {
        mouseTracerHolder!.removeDisConnectUser(data["userId"], data["socketId"]);
      });

      // 접속 중인 유저의 마우스 포인트의 좌표 데이터 수신
      socket.on("updateCursorPosition", (data) {
        mouseTracerHolder!.updateCursorPosition(data);
      });

    } catch (error) {
      logger.severe("error during connect socket server >>> $error");
    }

  }

  void changeCursorPosition(double dx, double dy) {
    socket.emit('changeCursorPosition', {
      'dx': dx,
      'dy': dy
    });
  }

  void disconnect() {
    healthCheckTimer?.cancel();
    mouseTracerHolder?.destroy();
    socket.disconnect();
    socket.dispose();
  }

  void startHealthCheck() {
    healthCheckTimer = Timer.periodic(const Duration(minutes: 3), (timer) { 
      if(!socket.connected) {
        disconnect();
        initialize("");
        connectServer(roomId);
      }
    });
  }

  int getRandomColor() {
    Random random = Random();
    int r = random.nextInt(256);
    int g = random.nextInt(256);
    int b = random.nextInt(256);

    // Color 객체로 변환하여 반환
    return Color.fromARGB(255, r, g, b).value;
  }
  
  



}