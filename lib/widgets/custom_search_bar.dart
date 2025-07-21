import 'package:flutter/material.dart';
import 'package:savourai/constant/colors.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? hintIcon;
  final Widget? submitIcon;
  final VoidCallback? onSubmit;
  final ValueChanged<String>? onChanged;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.hintIcon,
    required this.hintText,
    this.submitIcon,
    this.onSubmit,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // If hintIcon is provided, display it
          if (hintIcon != null) ...[hintIcon!, const SizedBox(width: 8)],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintStyle: const TextStyle(
                  color: AppColors.border,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (submitIcon != null && onSubmit != null)
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                if (onSubmit != null) {
                  onSubmit!();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: submitIcon,
              ),
            ),
        ],
      ),
    );
  }
}
