
import 'package:hycop/hycop/account/account_manager.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../../common/util/logger.dart';
import 'mouse_tracer.dart';
import '../../hycop/socket/socket_utils.dart';
// ignore: depend_on_referenced_packages
import 'package:socket_io_client/socket_io_client.dart';


class SocketClient {

  late Socket socket;
  late String roomID;

  
  void initialize() {
    socket = io(
      //"ws://localhost:4432",
      "https://hycop-socket.tk:443",
      //myConfig!.serverConfig!.socketConnInfo.serverUrl + myConfig!.serverConfig!.socketConnInfo.serverPort.toString(),  // url:port
      <String, dynamic> {
        "transports" : ['websocket'],
        "autoConnect" : false
      }
    );
  }

  Future<void> connectServer(String contentBookID) async {

    roomID = SocketUtils.getRoomID(contentBookID);
  

    socket.connect().onConnectError((err) => 
      throw HycopException(message: err.toString())
    );

    socket.emit("join", {
      "roomID" : roomID, 
      "userID" : AccountManager.currentLoginUser.email, 
      "userName" : AccountManager.currentLoginUser.name
    });


    socket.on("connect", (data) {
      logger.finest("connect");
    });
    socket.on("disconnect", (data) {
      logger.finest("disconnect");
      disconnect();
    });
    socket.on("joinUser", (data) {
      joinUser(data);
    });
    socket.on("leaveUser", (data) {
      leaveUser(data);
    });
    socket.on("changeData", (data) {
      changeData();
    });
    socket.on("changeCursor", (data) {
      changeCursor(data);
    });
    socket.on("focusFrameData", (data) {
      mouseTracerHolder!.focusFrame(data["userID"], data["frameID"]);
    });
    socket.on("unFocusFrameData", (data) {
      mouseTracerHolder!.unFocusFrame(data["userID"]);
    });
    
  }


  void joinUser(Map<String, dynamic> data) {
    mouseTracerHolder!.joinUser(data["userList"]);
  }

  void leaveUser(Map<String, dynamic> data) {
    mouseTracerHolder!.unFocusFrame(data["userID"]);
    mouseTracerHolder!.leaveUser(data["userID"]);
  }

  void updateData() {
    socket.emit("updateData", {
      "roomID" : roomID,
      "userID" : AccountManager.currentLoginUser.email,
      "message" : "",
      "changeDate" : DateTime.now().toString().substring(0, 16)
    });
  }

  void changeData() {
    // reload Data
  }

  void moveCursor(double dx, double dy) {
    socket.emit("moveCursor", {
      "roomID" : roomID,
      "userID" : AccountManager.currentLoginUser.email,
      "cursor_x" : dx,
      "cursor_y" : dy
    });
  }

  void changeCursor(Map<String, dynamic> data) {
    mouseTracerHolder!.changePosition(
      mouseTracerHolder!.getIndex(data["userID"]),
      data["cursor_x"],
      data["cursor_y"]
    );
  }

  void focusFrame(String frameID) {
    mouseTracerHolder!.focusFrame(AccountManager.currentLoginUser.email, frameID);
    socket.emit("focusFrame", {
      "roomID" : roomID,
      "userID" : AccountManager.currentLoginUser.email,
      "frameID" : frameID,
      "changeDate" : DateTime.now().toString().substring(0, 16)
    });
  }

  void unFocusFrame() {
    mouseTracerHolder!.unFocusFrame(AccountManager.currentLoginUser.email);
    socket.emit("unFocusFrame", {
      "roomID" : roomID,
      "userID" : AccountManager.currentLoginUser.email
    });
  }

  void disconnect() {
    socket.disconnect().onError((err) {
      throw HycopException(message: err.toString());
    });
    socket.destroy();
  }


}