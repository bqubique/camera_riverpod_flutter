import 'package:flutter/material.dart';

class CameraButton extends StatelessWidget {
  final VoidCallback callback;
  final Widget child;
  final ButtonStyle buttonStyle;
  const CameraButton({
    Key? key,
    required this.callback,
    required this.child,
    required this.buttonStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      child: ElevatedButton(
        onPressed: callback,
        style: buttonStyle,
        child: child,
      ),
    );
  }
}
