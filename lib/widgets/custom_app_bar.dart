import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final Color titleColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.backgroundColor = Colors.white,
    this.titleColor = Colors.black,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
