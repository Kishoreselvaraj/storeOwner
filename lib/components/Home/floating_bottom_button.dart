import 'package:flutter/material.dart';

class FloatingBottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  /// Visual tweaks (all optional)
  final double height;
  final double horizontalMargin;
  final double extraBottom; // e.g. add bottom-nav height here if needed
  final Color backgroundColor;
  final TextStyle? textStyle;
  final double borderRadius;
  final double elevation;

  const FloatingBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.horizontalMargin = 16,
    this.extraBottom = 12,
    this.backgroundColor = Colors.orange,
    this.textStyle,
    this.borderRadius = 12,
    this.elevation = 3,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      left: horizontalMargin,
      right: horizontalMargin,
      bottom: (bottomInset > 0 ? bottomInset : 0) + extraBottom,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          minimumSize: Size(double.infinity, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: elevation,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: textStyle ??
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
