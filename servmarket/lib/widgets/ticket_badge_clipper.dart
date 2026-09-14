import 'package:flutter/material.dart';

class TicketBadgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final notchRadius = size.height / 2;
    final notchDepth = notchRadius;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(notchDepth, size.height);
    path.arcToPoint(
      Offset(0, size.height / 2),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.arcToPoint(
      Offset(notchDepth, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.close();

    return path;
  }

  @override
  bool shouldReclip(TicketBadgeClipper oldClipper) => false;
}
