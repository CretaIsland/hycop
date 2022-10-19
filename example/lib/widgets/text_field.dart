import 'package:flutter/material.dart';

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(hintText: 'Password'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Cannot be empty';
        }
        return null;
      },
    );
  }
}

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(hintText: 'Email'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Cannot be empty';
        } else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(value)) {
          return 'Not a valid email address';
        }
        return null;
      },
    );
  }
}

class SimpleTextField extends StatelessWidget {
  const SimpleTextField({
    Key? key,
    required this.controller,
    required this.hintText,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(hintText: hintText),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Cannot be empty';
        }
        return null;
      },
    );
  }
}

class OnlyTextField extends StatelessWidget {
  final double fontSize;
  final Color color;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;

  const OnlyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.fontSize = 24,
    this.color = Colors.black,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly,
      style: TextStyle(color: color, fontSize: fontSize),
      controller: controller,
      decoration: InputDecoration(hintText: hintText),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Cannot be empty';
        }
        return null;
      },
    );
  }
}

class NameTextField extends StatelessWidget {
  final double fontSize;
  final Color color;
  final String name;
  final TextEditingController controller;
  final String hintText;
  final double inputSize;
  final bool readOnly;

  const NameTextField({
    Key? key,
    required this.name,
    required this.controller,
    this.hintText = '',
    this.inputSize = 400,
    this.fontSize = 24,
    this.color = Colors.black,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: TextStyle(color: color, fontSize: fontSize),
        ),
        // const SizedBox(
        //   width: 20,
        // ),
        SizedBox(
          width: inputSize,
          child: TextFormField(
            readOnly: readOnly,
            style: TextStyle(color: color, fontSize: fontSize),
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class BasicTextField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;

  final String labelText;
  final bool enabled;
  final bool readOnly;
  final bool showCusor;
  final bool autofocus;
  final double borderWidth;
  final int? maxLine;

  const BasicTextField(
      {Key? key,
      required this.controller,
      this.onChanged,
      this.onEditingComplete,
      this.onSubmitted,
      this.labelText = '',
      this.enabled = true,
      this.readOnly = false,
      this.showCusor = true,
      this.autofocus = true,
      this.borderWidth = 1,
      this.maxLine})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
        readOnly: readOnly,
        enabled: enabled,
        onChanged: onChanged ?? (val) {},
        onEditingComplete: onEditingComplete ?? () {},
        onSubmitted: onSubmitted ?? (val) {},
        //key: ValueKey(Uuid().v4()),
        keyboardType: TextInputType.text,
        autofocus: autofocus,
        showCursor: showCusor,
        cursorColor: Colors.white,
        cursorWidth: 3,
        maxLines: maxLine,
        controller: controller,
        decoration: InputDecoration(
            labelText: labelText,
            isDense: true,
            contentPadding: const EdgeInsets.all(8),
            enabledBorder: borderWidth > 0
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      //width: 1, style: BorderStyle.solid, color: MyColors.secondaryColor),
                      width: borderWidth,
                      style: BorderStyle.solid,
                      //color: MyColors.secondaryColor
                    ),
                  )
                : null,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                width: 1,
                style: BorderStyle.solid,
                //color: MyColors.mainColor
              ),
            ),
            filled: true,
            suffixIcon: IconButton(
              //constraints: BoxConstraints.tight(Size(16, 16)),
              padding: const EdgeInsets.only(right: 5),
              //color: MyColors.mainColor,
              //iconSize: MySizes.smallIcon,
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
              },
            )));
  }
}
