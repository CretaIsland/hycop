import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hycop/hycop/webrtc/webrtc_client.dart';
import 'package:routemaster/routemaster.dart';

import '../../navigation/routes.dart';

class LeaveBtn extends StatelessWidget {
  LeaveBtn({ Key? key, required this.screenHeight }) : super(key: key);
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(CircleBorder()),
        padding: MaterialStateProperty.all(EdgeInsets.all(8)),
        backgroundColor: MaterialStateProperty.all(Colors.red), // <-- Button color
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) return Colors.red.shade900; // <-- Splash color
        }),
        shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) return Colors.red; // <-- Splash color
        }),
      ),
      onPressed: () {
        webRTCClient!.close();
        Routemaster.of(context).push(AppRoutes.webRtcExampleWaitingroom);
      },
      child: Icon(
        Icons.call_end,
        color: Colors.white,
        size: screenHeight * .05,
      ),
    );
  }
}
