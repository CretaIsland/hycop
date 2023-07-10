// ignore: depend_on_referenced_packages
import 'package:socket_io_client/socket_io_client.dart';
import 'package:hycop/hycop/socket/mouse_tracer.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'dart:async';


class SocketClient {

  late Socket socket;
  late String roomId;
  Timer? healthCheckTimer;


  void initialize(String serverUrl) {
    socket = io(
      serverUrl,
      <String, dynamic> {
        "transports" : ["websocket"],
        "autoConnect" : false
      }
    );
  }

  Future<void> connectServer(String socketRoomId) async {

    roomId = socketRoomId;

    socket.connect().onError((err) => throw Exception());
    startHealthCheckTimer();
    socket.emit("join", {
      "roomId" : roomId,
      "userId" : AccountManager.currentLoginUser.email,
      "userName" : AccountManager.currentLoginUser.name
    });
    

    socket.on("connect", (data) {
    });
    socket.on("disconnect", (data) {
      socket.dispose();
    });
    socket.on("receiveOtherInfo", (data) {
      mouseTracerHolder!.receiveOtherInfo(data["userList"]);
    });
    socket.on("receiveNewInfo", (data) {
      mouseTracerHolder!.receiveNewInfo(data["userInfo"]);
    }); 
    socket.on("leaveUser", (data) {
      mouseTracerHolder!.leaveUser(data["socketId"]);
    }); 
    socket.on("updateCursor", (data) {
      mouseTracerHolder!.updateCursor(data);
    });
  }

  void moveCursor(double dx, double dy) {
  socket.emit("moveCursor", {
      "userId" : AccountManager.currentLoginUser.email,
      "dx" : dx,
      "dy" : dy
    });
  }

  void disconnect() {
    healthCheckTimer?.cancel();
    socket.disconnect().onError((err) => throw Exception());
    socket.destroy();
  }

  void startHealthCheckTimer() {
    healthCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!socket.connected) {
        disconnect();
        connectServer(roomId);
      }
    });
  }


}