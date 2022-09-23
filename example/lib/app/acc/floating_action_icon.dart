import 'package:flutter/material.dart';
import 'acc_const.dart';

class FloatingActionIcon extends StatefulWidget {
  //const FloatingActionIcon({Key? key}) : super(key: key);
  final IconData iconData;
  final VoidCallback? onTap;

  const FloatingActionIcon({
    Key? key,
    required this.iconData,
    this.onTap,
  }) : super(key: key);
  @override
  State<FloatingActionIcon> createState() => FloatingActionIconState();
}

class FloatingActionIconState extends State<FloatingActionIcon> {
  final double _size = 12;
  final double _enlarge = 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.hardEdge,
      shape: const CircleBorder(),
      child: InkWell(
        // onHover: (value) {
        //   setState(() {
        //     _size = value ? 24 : 12;
        //     _enlarge = value ? 2 : 1;
        //   });
        // },
        onTap: widget.onTap,
        child: SizedBox(
          height: floatingActionDiameter * _enlarge,
          width: floatingActionDiameter * _enlarge,
          child: Center(
            child: Icon(
              widget.iconData,
              color: Colors.blue,
              size: _size,
            ),
          ),
        ),
      ),
    );
  }
}

// class FloatingActionIcon extends StatelessWidget {
//   const FloatingActionIcon({
//     Key? key,
//     required this.iconData,
//     this.onTap,
//   }) : super(key: key);

//   final IconData iconData;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       clipBehavior: Clip.hardEdge,
//       shape: const CircleBorder(),
//       child: InkWell(
//         onTap: onTap,
//         child: SizedBox(
//           height: floatingActionDiameter,
//           width: floatingActionDiameter,
//           child: Center(
//             child: Icon(
//               iconData,
//               color: Colors.blue,
//               size: 12,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
