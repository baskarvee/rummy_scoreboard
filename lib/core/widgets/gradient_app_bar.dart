import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An AppBar wrapped in the brand gradient, used on all primary screens.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (subtitle != null ? 20 : 0) + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.headerDecoration,
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: leading,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: actions,
        bottom: bottom,
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
    );
  }
}
