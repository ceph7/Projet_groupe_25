import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppTheme.primaryColor;
    final logoSize = size ?? 32.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icone stylisée - pas un bouton
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: logoColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: logoSize * 0.55,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Texte du logo
        Text(
          'ServMarket',
          style: TextStyle(
            fontSize: logoSize * 0.85,
            fontWeight: FontWeight.w700,
            color: logoColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
