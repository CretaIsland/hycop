import 'package:flutter/material.dart';

class GlowingButton extends StatefulWidget {
  final Color color1;
  final Color color2;
  final String text;
  final IconData icon1;
  final IconData icon2;
  final void Function() onPressed;
  final double width;
  final double height;
  final double fontSize;

  const GlowingButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon1 = Icons.lightbulb,
    this.icon2 = Icons.lightbulb_outline,
    this.color1 = Colors.cyan,
    this.color2 = Colors.greenAccent,
    this.width = 160,
    this.height = 40,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                glowing ? widget.icon1 : widget.icon2,
                color: Colors.white,
                size: widget.fontSize,
              ),
              SizedBox(
                width: widget.fontSize,
              ),
              Text(
                widget.text,
                style: TextStyle(
                    color: Colors.white, fontSize: widget.fontSize, fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      ),
    );
  }
}
