// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/webrtc/media_stream.dart';
import 'package:hycop/hycop/webrtc/webrtc_client.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';
import '../widgets/widget_snippets.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';

class WebRTCExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;
  const WebRTCExamplePage({Key? key, this.openDrawer}) : super(key: key);
  @override
  State<WebRTCExamplePage> createState() => _WebRTCExamplePageState();
}

class _WebRTCExamplePageState extends State<WebRTCExamplePage> {

  WebRTCClient webRTCClient = WebRTCClient();
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  @override
  void initState() {
    super.initState();

    webRTCMediaStreamHolder = WebRTCMediaStream();
    webRTCMediaStreamHolder!.init().then((value) {
      webRTCClient.initialize();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WebRTCMediaStream>.value(value: webRTCMediaStreamHolder!)
      ],
      child: Scaffold(
        appBar: AppBar(
          actions: WidgetSnippets.hyAppBarActions(context),
          backgroundColor: Colors.orange,
          title: const Text('WebRTC Example'),
          leading: DrawerMenuWidget(onClicked: () {
            if (widget.openDrawer != null) {
              widget.openDrawer!();
            } else {
              Routemaster.of(context).push(AppRoutes.main);
            }
          }),
        ),
        body: Consumer<WebRTCMediaStream>(builder: (context, webRTCMediaStreamManager, child) {
          return Row(
            children: [
              Container(
                width: screenWidth * .8,
                height: screenHeight - 50,
                color: Colors.black,
                child: Column(
                  children: [
                    SizedBox(
                      width: screenWidth,
                      height: screenHeight - 150,
                      child: RTCVideoView(webRTCMediaStreamManager.localRenderer!),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {}, 
                          icon: const Icon(Icons.camera, color: Colors.white, size: 40)
                        ),
                        const SizedBox(
                          width: 30.0,
                        ),
                        IconButton(
                          onPressed: () {}, 
                          icon: const Icon(Icons.mic, color: Colors.white, size: 40)
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                width: screenWidth * .2,
                height: screenHeight - 50,
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    var remoteKeys = webRTCMediaStreamManager.remoteRenderer.keys.toList();
                    return videoView(webRTCMediaStreamManager, remoteKeys[index]);
                  },
                  itemCount: webRTCMediaStreamManager.remoteRenderer.length,
                ),
              )
            ],
          );
        })
      )
    );
  }

  Widget videoView(WebRTCMediaStream webRTCMediaStreamManager, String userSocketID) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
      width: 200,
      height: 220,
      color: Colors.orange,
      child: RTCVideoView(webRTCMediaStreamManager.remoteRenderer[userSocketID]!),
    );
  }

}