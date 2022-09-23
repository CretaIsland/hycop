import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hycop/common/util/logger.dart';

// ignore: must_be_immutable
class TwinCardFlip extends StatefulWidget {
  final Widget firstPage;
  final Widget secondPage;
  final bool flip;

  TwinCardFlip({
    Key? key,
    required this.firstPage,
    required this.secondPage,
    required this.flip,
  }) : super(key: key);

  bool isBack = true;
  double angle = 0;

  @override
  TwinCardFlipState createState() => TwinCardFlipState();
}

class TwinCardFlipState extends State<TwinCardFlip> {
  @override
  void initState() {
    super.initState();
  }

  Widget frostedEdged({required Widget child}) {
    return ClipRRect(
        //borderRadius: BorderRadius.circular(15.0),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), child: child));
  }
  // void _flip() {
  //   logHolder.log('card fliped--------------------------------------', level: 5);
  //   setState(() {
  //     angle = (angle + pi) % (2 * pi);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    if (!widget.flip) {
      widget.angle = 0;
    } else {
      widget.angle = (widget.angle + pi) % (2 * pi);
    }
    logger.finest(
      'angle=${widget.flip}, ${widget.angle}------------------------',
    );
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              //onTap: _flip,
              child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: widget.angle),
                  duration: const Duration(milliseconds: 500),
                  builder: (BuildContext context, double val, __) {
                    if (val >= (pi / 2)) {
                      widget.isBack = false;
                    } else {
                      widget.isBack = true;
                    }

                    return (Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(val),
                      child: widget.isBack
                          ? Container(
                              child: widget.firstPage,
                            )
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: widget.secondPage,
                            ),
                    ));
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
