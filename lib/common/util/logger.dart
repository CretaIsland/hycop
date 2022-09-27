//import 'package:flutter/foundation.dart';
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state.dart';
import 'package:logging/logging.dart';

final logger = Logger('App');

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void setupLogger() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((record) {
    String emoji = '';
    if (record.level == Level.INFO) {
      emoji = 'ℹ️';
    } else if (record.level == Level.WARNING) {
      emoji = '❗️';
    } else if (record.level == Level.SEVERE) {
      emoji = '⛔️';
    }
    debugPrint('$emoji   ${record.level.name}: ${record.message}');
    if (record.error != null) {
      debugPrint('👉 ${record.error}');
    }
    if (record.level == Level.SEVERE) {
      debugPrint('👉 ${record.error}');
      //debugPrintStack(stackTrace: record.stackTrace);
    }
  });
}

extension RefX on WidgetRef {
  void errorStateListener(
    BuildContext context,
    ProviderListenable<StateBase> provider,
  ) {
    listen<StateBase>(provider, ((previous, next) {
      final message = next.error?.message;
      if (next.error != previous?.error && message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }));
  }

  void errorControllerStateListener(
    BuildContext context,
    ProviderListenable<ControllerStateBase> provider,
  ) {
    listen<ControllerStateBase>(provider, ((previous, next) {
      final message = next.error?.message;
      if (next.error != previous?.error && message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }));
  }
}



// // ignore_for_file: avoid_print, prefer_const_constructors
// import 'dart:collection';
// import 'package:flutter/material.dart';

// MyLogger trace = MyLogger();

// class MyLogger {
//   bool showLog = false;
//   int levelLimit = 8;
//   int maxMsg = 100;
//   final veiwerKey = GlobalKey<DebugBarState>();
//   Queue<String> msgList = ListQueue();

//   MyLogger() {
//     msgList.add('ready');
//   }

//   void log(String msg, {int level = 1, bool force = false}) {
//     if (force || (level >= levelLimit)) {
//       print(msg);
//       if (showLog && veiwerKey.currentState != null) {
//         msgList.add(msg);
//         if (msgList.length >= maxMsg) {
//           msgList.removeFirst();
//         }
//         //notifyListeners();
//       }
//     }
//   }

//   void warning(String msg) {
//     log("Warning : $msg", force: true);
//   }

//   void error(String msg) {
//     log("Error : $msg", force: true);
//   }
// }

// class DebugBar extends StatefulWidget {
//   const DebugBar({Key? key}) : super(key: key);
//   @override
//   DebugBarState createState() => DebugBarState();
// }

// class DebugBarState extends State<DebugBar> {
//   @override
//   void setState(VoidCallback fn) {
//     if (mounted) super.setState(fn);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 100,
//       color: Colors.red.withOpacity(0.7),
//       child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 1,
//               child: ElevatedButton(
//                   onPressed: () {
//                     setState(() {});
//                   },
//                   child: const Icon(Icons.refresh)),
//             ),
//             Expanded(
//               flex: 19,
//               child: Scrollbar(
//                 thickness: 20,
//                 //hoverThickness: 25,
//                 //isAlwaysShown: true,
//                 thumbVisibility: true,
//                 //showTrackOnHover: true,
//                 child: ListView(
//                   padding: EdgeInsets.only(left: 20),
//                   shrinkWrap: true,
//                   children: List.generate(trace.msgList.length, (index) {
//                     return Text(trace.msgList.toList()[index]);
//                   }),
//                 ),
//               ),
//             ),
//           ]),
//     );
//   }
// }
