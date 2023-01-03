import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hycop/hycop/webrtc/media_devices/media_devices_data.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:hycop/hycop/webrtc/webrtc_client.dart';
import 'package:provider/provider.dart';

class VideoBtn extends StatelessWidget {
  VideoBtn({Key? key, required this.screenHeight }) : super(key: key);
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProducerData>.value(value: producerDataHolder!)
      ],
      child: Consumer<ProducerData>(
        builder: (context, producerDataManager, child) {
          if(mediaDeviceDataHolder!.videoInputs!.length == 0) {
            return IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.videocam,
                color: Colors.grey,
                size: screenHeight * .05,
              ),
            );
          }
          if(producerDataManager.webcam == null) {
            return ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(CircleBorder()),
                padding: MaterialStateProperty.all(EdgeInsets.all(8)),
                backgroundColor: MaterialStateProperty.all(Colors.white),
                overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.pressed)) return Colors.grey;
                }),
                shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.pressed)) return Colors.grey;
                }),
              ),
              onPressed: () {
                if(producerDataHolder!.webcam == null) {
                  webRTCClient!.enableWebcam();
                }
              },
              child: Icon(
                Icons.videocam_off,
                color: Colors.black,
                size: screenHeight * .05
              ),
            );
          }
          return ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(CircleBorder()),
              padding: MaterialStateProperty.all(EdgeInsets.all(8)),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.pressed)) return Colors.grey;
              }),
              shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.pressed)) return Colors.grey;
              }),
            ),
            onPressed: () {
              if (producerDataManager.webcam != null) {
                webRTCClient!.disableWebcam();
              }
            },
            child: Icon(
              Icons.videocam,
              color: Colors.black,
              size: screenHeight * .05
            ),
          );
        }
      ),
    );
  }
}
