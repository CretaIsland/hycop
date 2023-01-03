import 'package:example/app/webrtc_example_page/stream/list_remote_streams.dart';
import 'package:flutter/material.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/webrtc/webrtc_client.dart';
import 'package:random_string/random_string.dart';

import 'component/audio_btn.dart';
import 'component/leave_btn.dart';
import 'component/video_btn.dart';
import 'stream/local_stream.dart';

class MeetingRoomPage extends StatefulWidget {
  MeetingRoomPage({Key? key, required this.roomId}) : super(key: key);
  final String roomId;
  @override
  _MeetingRoomPageState createState() => _MeetingRoomPageState();
}

class _MeetingRoomPageState extends State<MeetingRoomPage> {


  @override
  void initState() {
    super.initState();
    webRTCClient = WebRTCClient(
      roomId: widget.roomId, 
      peerId: AccountManager.currentLoginUser.email, 
      url: 'wss://v3demo.mediasoup.org:4443', 
      displayName: randomAlpha(8).toLowerCase()
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 8,
            child: Column(
              children: [
                Expanded(
                  flex: 9,
                  child: Container(
                    width: screenWidth * .8,
                    height: screenHeight * .9,
                    color: Colors.black,
                    child: LocalStream(),
                  )
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: screenWidth * .8,
                    height: screenHeight * .1,
                    child: Row(
                      children: [
                        VideoBtn(screenHeight: screenHeight),
                        AudioBtn(screenHeight: screenHeight),
                        LeaveBtn(screenHeight: screenHeight),
                      ],
                    )
                  )
                ),
              ],
            )
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey,
              child: ListRemoteStreams(screenHeight: screenHeight, screenWidth: screenWidth * .2),
            )
          )
        ],
      ),
    );
  }
}
