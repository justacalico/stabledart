import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28, this.asset = 'assets/images/icon.png'});

  final double size;
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.dashboard_customize, size: size),
      );
}
