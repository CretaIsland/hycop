import 'package:flutter/cupertino.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/common/util/logger.dart';

WebRTCMediaStream? webRTCMediaStreamHolder;

class WebRTCMediaStream extends ChangeNotifier {

  MediaStream? localMediaStream;
  RTCVideoRenderer? localRenderer;

  Map<String, MediaStream?> remoteMediaStreams= {}; 
  Map<String, RTCVideoRenderer> remoteRenderer = {};

  // local MediaStream 정의
  Future<void> init() async {
    localRenderer = RTCVideoRenderer();
    await localRenderer!.initialize();
    localMediaStream = await navigator.mediaDevices.getUserMedia({
      "audio" : true,
      "video" : true
    });
    localRenderer!.srcObject = localMediaStream;
    notifyListeners();
  }

  void notify() => notifyListeners();

  Future<void> leave() async {
    for (var element in remoteRenderer.keys) {
      remoteRenderer[element]!.dispose();
      remoteMediaStreams[element]!.dispose();
    }
    remoteRenderer.clear();
    remoteMediaStreams.clear();
    localMediaStream!.dispose();
    localRenderer!.dispose();
    notifyListeners();
  }

  Future<void> userEnter(String socketID) async {
    logger.finest("userEnter");
    remoteRenderer[socketID] = RTCVideoRenderer();
    await remoteRenderer[socketID]!.initialize();
    notifyListeners();
  }

  void getUserMedia(RTCTrackEvent track, String socketID) {
    logger.finest("getuserMedia");
    remoteMediaStreams[socketID] = track.streams[0];
    remoteRenderer[socketID]!.srcObject = remoteMediaStreams[socketID];
    logger.finest( remoteMediaStreams[socketID]!.id);
    notifyListeners();
  }

  Future<void> userLeave(String socketID) async {
    remoteRenderer[socketID]!.dispose();
    remoteRenderer.remove(socketID);
    notifyListeners();
  }




}