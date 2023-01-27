// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
//import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/hycop/webrtc/media_devices/media_devices_data.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:hycop/hycop/webrtc/webrtc_client.dart';
import 'package:provider/provider.dart';

class AudioBtn extends StatelessWidget {
  const AudioBtn({Key? key, required this.screenHeight}) : super(key: key);
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<ProducerData>.value(value: producerDataHolder!)],
      child: Consumer<ProducerData>(
        builder: (context, producerDataManager, child) {
          if (mediaDeviceDataHolder!.audioInputs!.isEmpty) {
            return IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.mic_off,
                color: Colors.blueGrey,
                size: screenHeight * .05,
              ),
            );
          } else {
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
                if (producerDataManager.mic?.paused == true) {
                  webRTCClient!.unmuteMic();
                } else {
                  webRTCClient!.muteMic();
                }
              },
              child: Icon(
                producerDataManager.mic?.paused == true ? Icons.mic_off : Icons.mic,
                color: producerDataManager.mic == null ? Colors.grey : Colors.black,
                size: screenHeight * .05,
              ),
            );
          }
        },
      ),
    );
  }
}
