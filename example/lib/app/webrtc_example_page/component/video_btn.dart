// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hycop/hycop/webrtc/media_devices/media_devices_data.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:hycop/hycop/webrtc/webrtc_client.dart';
import 'package:provider/provider.dart';

class VideoBtn extends StatelessWidget {
  const VideoBtn({Key? key, required this.screenHeight}) : super(key: key);
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<ProducerData>.value(value: producerDataHolder!)],
      child: Consumer<ProducerData>(builder: (context, producerDataManager, child) {
        if (mediaDeviceDataHolder!.videoInputs!.isEmpty) {
          return IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.videocam,
              color: Colors.grey,
              size: screenHeight * .05,
            ),
          );
        }
        if (producerDataManager.webcam == null) {
          return ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(CircleBorder()),
              padding: MaterialStateProperty.all(EdgeInsets.all(8)),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.pressed)) return Colors.grey;
                return null;
              }),
              shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.pressed)) return Colors.grey;
                return null;
              }),
            ),
            onPressed: () {
              if (producerDataHolder!.webcam == null) {
                webRTCClient!.enableWebcam();
              }
            },
            child: Icon(Icons.videocam_off, color: Colors.black, size: screenHeight * .05),
          );
        }
        return ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(CircleBorder()),
            padding: MaterialStateProperty.all(EdgeInsets.all(8)),
            backgroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) return Colors.grey;
              return null;
            }),
            shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) return Colors.grey;
              return null;
            }),
          ),
          onPressed: () {
            if (producerDataManager.webcam != null) {
              webRTCClient!.disableWebcam();
            }
          },
          child: Icon(Icons.videocam, color: Colors.black, size: screenHeight * .05),
        );
      }),
    );
  }
}
