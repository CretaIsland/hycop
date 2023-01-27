// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/hycop/webrtc/peers/enitity/peer.dart';

class RemoteStream extends StatelessWidget {
  final Peer peer;
  final double screenHeight;
  final double screenWidth;
  RemoteStream(
      {required Key key, required this.peer, required this.screenHeight, required this.screenWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth,
      height: screenHeight,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (peer.renderer != null && peer.video != null)
            RTCVideoView(peer.renderer!)
          else
            Icon(Icons.person, size: screenHeight),
          Positioned(
              bottom: 0,
              child: Container(
                  width: screenWidth,
                  height: 25,
                  color: Colors.black,
                  child: Text("${peer.id}의 화면",
                      style: TextStyle(color: Colors.white), textAlign: TextAlign.left)))
        ],
      ),
    );
  }
}
