import 'package:flutter/material.dart';

class ImageShadow extends StatelessWidget {
  const ImageShadow({Key? key, required this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: const Offset(-4, 2),
            color: Color.fromRGBO(150, 150, 150, 1),
            blurRadius: 2.6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
