import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/common/util/logger.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'media_stream.dart';

class WebRTCClient{

  late final IO.Socket socket;
  RTCPeerConnection? localPC;
  Map<String, RTCPeerConnection> remotePCs = {};

  String socketID = "";

  final pcConfig = {
    "iceServers": [
      { "urls": ["stun:stun1.l.google.com:19302" ] }
    ],
  };

  void initialize() {
    connectSocket();
  }

  // 다른 사용자의 MediaStream을 받을 PeerConnection 생성
  Future<void> createReceivePC(String userSocketID) async {
    try {
      logger.finest(">>>>> createReceivePC ");
      RTCPeerConnection pc = await createReceiverPeerConnection(userSocketID);
      await createReceiverOffer(pc, userSocketID);
    } catch (error) {
      logger.finest(error.toString());
    }
  }

  // 본인의 MediaStream을 보낼 PeerConnection의 offer 생성
  Future<void> createSenderOffer(String senderSocketID) async {
    try {
      logger.finest(">>>>> createSenderOffer ");
      var offer = await localPC!.createOffer({
        "offerToReceiveAudio" : true,
        "offerToReceiveVideo" : true
      });
      await localPC!.setLocalDescription(offer);
      logger.finest("setLocalDescription 호출");

      socket.emit("senderOffer", {
        "sdp" : offer.sdp,
        "type" : offer.type,
        "senderSocketID" : senderSocketID,
        "roomID" : "room1234"
      });
    } catch (error) { 
      logger.finest(error.toString());
    }
  }

  // 다른 사용자의 MediaStream을 받을 PeerConnection의 offer 생성
  // sdp : 스트리밍하는 미디어의 해상도, 형식, 코덱 등 컨텐츠의초기 인수를 설명하기 위한 프로토콜. 비디오의 해상도, 오디오 전송 여부 등에 대한 데이터.
  Future<void> createReceiverOffer(RTCPeerConnection pc, String senderSocketID) async {
    try {
      logger.finest(">>>>> createReceiverOffer ");
      var offer = await pc.createOffer({
        "offerToReceiveAudio" : true,
        "offerToReceiveVideo" : true
      });
      await pc.setLocalDescription(offer);

      socket.emit("receiverOffer", {
        "sdp" : offer.sdp,
        "type" : offer.type,
        "receiverSocketID" : socketID,
        "senderSocketID" : senderSocketID,
        "roomID" : "room1234"
      });
    } catch (error) {
      logger.finest(error.toString());
    }
  }

  // 본인의 MediaStream을 보낼 PeerConnection을 생성하고 localStream을 add.
  Future<void> createSenderPeerConnection(MediaStream stream, String senderSocketID) async {
    logger.finest(">>>>> createSenderPeerConnection ");
    localPC = await createPeerConnection(pcConfig);

    logger.finest("최초 상태 : ${localPC!.iceConnectionState}");

    localPC!.onIceCandidate = (ice) {
      logger.finest("senderPC onICeCandidate");
      logger.finest("onIceCandidate : ${localPC!.iceConnectionState}");
      socket.emit("senderCandidate", {
        "candidate" : ice.candidate,
        "sdpMid" : ice.sdpMid,
        "sdpMLineIndex" : ice.sdpMLineIndex,
        "senderSocketID" : senderSocketID
      });
    };

    localPC!.onIceConnectionState = (state) {
      logger.finest("senderPC onIceConnectionState");
      logger.finest(state);
    };

    webRTCMediaStreamHolder!.localMediaStream!.getTracks().forEach((track) {
      localPC!.addTrack(track, webRTCMediaStreamHolder!.localMediaStream!);
    });

  }

  // 다른 사용자의 MediaStream을 받을 PeerConnection을 생성하고 서버로부터 온 다른 사용자의 MediaStream을 remoteMediaStream에 저장
  Future<RTCPeerConnection> createReceiverPeerConnection(String senderSocketID) async {
    logger.finest(">>>>> createReceiverPeerConnection ");

    var pc = await createPeerConnection(pcConfig);
    remotePCs[senderSocketID] = pc;
    await webRTCMediaStreamHolder!.userEnter(senderSocketID);

    pc.onIceCandidate = (ice) {
      logger.finest("receiverPC onICeCandidate");
      socket.emit("receiverCandidate", {
        "candidate" : ice.candidate,
        "sdpMid" : ice.sdpMid,
        "sdpMLineIndex" : ice.sdpMLineIndex,
        "senderSocketID" : senderSocketID,
        "receiverSocketID" : socketID
      });
    };

    pc.onIceConnectionState = (state) {
      logger.finest("receiverPC onIceConnectionState");
      logger.finest(state);
    };

    pc.onTrack = (track) {
      webRTCMediaStreamHolder!.getUserMedia(track, senderSocketID);
    };

    return pc;
  }

  // 방에 접속하고, 본인의 MediaStream을 정의
  Future<void> join() async {
    try {
      logger.finest(">>>>> join ");
      await webRTCMediaStreamHolder!.init();
      await createSenderPeerConnection(webRTCMediaStreamHolder!.localMediaStream!, socketID);
      await createSenderOffer(socketID);

      socket.emit("joinRoom", {
        "id": socketID,
        "roomID" : "room1234"
      });
    } catch (error) {
      logger.finest(error.toString());
    }
  }


  // Socket Connect
  Future<void> connectSocket() async {
    socket = IO.io("http://192.168.102.111:4434", IO.OptionBuilder().setTransports(["websocket"]).build());
    socket.connect().onError((data) => logger.finest("connect socket!"));
    socket.emit("init");  // socketID 요청

    socket.on("getSocketID", (data) {
      socketID = data["socketID"];
      join();
    });

    // 새로운 사용자가 접속했을 때, 해당 사용자의 MediaStream을 받기 위한 PeerConnection 생성
    socket.on("userEnter", (data) {
      createReceivePC(data["id"]);
    });

    // 사용자가 접속했을 때, 이미 접속해있던 사용자들의 MediaStream을 받기 위한 PeerConnection 생성
    socket.on("allUsers", (data) {
      for(int i = 0; i < data["users"].length; i++) {
        createReceivePC(data["users"][i]["id"]);
      }
    });

    // 사용자가 접속을 해제했을 때 사용하던 PeerConnection 삭제
    socket.on("userExit", (data) {
      remotePCs[data["id"]]!.close();
      remotePCs.remove(data["id"]);
    });

    // 서버로부터 answer로 온 RTCSessionDescription을 본인의 MediaStream을 보낼 때 사용하는 PeerConnection에 set.
    socket.on("getSenderAnswer", (data) async {
      try {
        logger.finest("getSenderAnswer 호출");
        logger.finest(data);
        await localPC!.setRemoteDescription(RTCSessionDescription(data["sdp"], data["type"]));
      } catch (error) {
        logger.finest(error.toString());
      }
    });

    // 본인의 MediaStream을 보내기 위한 PeerConnection을 위해 서버에서 보낸 IceCandidate를 add.
    socket.on("getSenderCandidate", (data) async {
      try {
        logger.finest("get sender candidate");
        logger.finest(data);
        await localPC!.addCandidate(RTCIceCandidate(data["candidate"], data["sdpMid"], data["sdpMLineIndex"]));
      } catch (error) {
        logger.finest(error.toString());
      }
    });

    // 서버로부터 answer로 온 RTCSessionDescription을 다른 사용자의 MediaStream을 받기 위한 PeerConnection에 set.
    socket.on("getReceiverAnswer", (data) async {
      try {
        await remotePCs[data["id"]]!.setRemoteDescription(RTCSessionDescription(data["sdp"], data["type"]));
      } catch (error) {
        logger.finest(error.toString());
      }
    });

    // 다른 사용자의 MediaStream을 받기 위한 PeerConnection을 위해 서버에서 보낸 RTCIceCandidate를 add.
    socket.on("getReceiverCandidate", (data) async {
      try {
        logger.finest("get receiver candidate");
        await remotePCs[data["id"]]!.addCandidate(RTCIceCandidate(data["candidate"], data["sdpMid"], data["sdpMLineIndex"]));
      } catch (error) {
        logger.finest(error.toString());
      }
    });

  }


}