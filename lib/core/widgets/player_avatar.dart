import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.index,
    this.radius = 20,
    this.fontSize,
  });

  final String name;
  final int index;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final color = AppTheme.avatarColor(index);
    final fSize = fontSize ?? (radius * 0.6);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
