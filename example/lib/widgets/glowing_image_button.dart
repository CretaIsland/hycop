import 'package:flutter/material.dart';

class GlowingImageButton extends StatefulWidget {
  final Color color1;
  final Color color2;
  final String assetPath;
  final void Function() onPressed;
  final double width;
  final double height;

  const GlowingImageButton({
    Key? key,
    required this.assetPath,
    required this.onPressed,
    this.color1 = Colors.cyan,
    this.color2 = Colors.greenAccent,
    this.width = 160,
    this.height = 40,
  }) : super(key: key);

  @override
  State<GlowingImageButton> createState() => _GlowingImageButtonState();
}

class _GlowingImageButtonState extends State<GlowingImageButton> {
  bool glowing = false;
  double scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (detais) {
        widget.onPressed.call();
      },
      child: MouseRegion(
        onExit: (val) {
          setState(() {
            glowing = false;
            scale = 1.0;
          });
        },
        onEnter: (val) {
          setState(() {
            glowing = true;
            scale = 1.1;
          });
        },
        child: AnimatedContainer(
          transform: Matrix4.identity()..scale(scale),
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: [widget.color1, widget.color2],
            ),
            boxShadow: glowing
                ? [
                    BoxShadow(
                      color: widget.color1.withOpacity(0.6),
                      spreadRadius: 3,
                      blurRadius: 16,
                      offset: const Offset(-8, 0),
                    ),
                    BoxShadow(
                      color: widget.color2.withOpacity(0.6),
                      spreadRadius: 3,
                      blurRadius: 16,
                      offset: const Offset(8, 0),
                    ),
                    BoxShadow(
                      color: widget.color1.withOpacity(0.2),
                      spreadRadius: 16,
                      blurRadius: 32,
                      offset: const Offset(-8, 0),
                    ),
                    BoxShadow(
                      color: widget.color2.withOpacity(0.2),
                      spreadRadius: 16,
                      blurRadius: 32,
                      offset: const Offset(8, 0),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Image(
                image: AssetImage(widget.assetPath),
                width: widget.width,
                height: widget.height,
                fit: BoxFit.scaleDown,
                alignment: FractionalOffset.center),
          ),
        ),
      ),
    );
  }
}
