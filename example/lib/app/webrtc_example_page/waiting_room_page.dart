// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hycop/hycop/webrtc/media_devices/media_devices_data.dart';
import 'package:hycop/hycop/webrtc/peers/peers_data.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:routemaster/routemaster.dart';
import 'package:random_string/random_string.dart';
import '../navigation/routes.dart';

class WaitingRoomPage extends StatefulWidget {
  const WaitingRoomPage({super.key});
  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  final TextEditingController roomIdFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = DevHttpOverrides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Hycop WebRTC SFU",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                  width: 200,
                  height: 50,
                  child: TextField(
                    controller: roomIdFieldController,
                    decoration: const InputDecoration(
                        labelText: 'enter room id (empty = random id)',
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                            borderSide: BorderSide(width: 2, color: Colors.blue)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                            borderSide: BorderSide(width: 2, color: Colors.blue))),
                  )),
              const SizedBox(width: 15),
              IconButton(
                  padding: EdgeInsets.zero, // 패딩 설정
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    mediaDeviceDataHolder = MediaDeviceData();
                    peersDataHolder = PeersData();
                    producerDataHolder = ProducerData();
                    mediaDeviceDataHolder!.loadMediaDevice().then((value) {
                      if (roomIdFieldController.text.isEmpty) {
                        Routemaster.of(context).push(AppRoutes.webRtcExampleMeetingroom,
                            queryParameters: {"roomId": randomAlpha(8).toLowerCase()});
                      } else {
                        Routemaster.of(context).push(AppRoutes.webRtcExampleMeetingroom,
                            queryParameters: {"roomId": roomIdFieldController.text});
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_circle_right_outlined, size: 30, color: Colors.blue))
            ],
          )
        ],
      ),
    ));
  }
}

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
