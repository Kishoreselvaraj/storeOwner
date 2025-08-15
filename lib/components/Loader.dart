import 'dart:math' as math;
import 'package:flutter/material.dart';

class Loader extends StatefulWidget {
  const Loader({
    super.key,
    this.message,
    this.color = const Color(0xFFFF8D29), // #FF8D29
    this.dotSize = 12,
    this.gap = 6,
    this.height = 50,
    this.amplitude = 10,                  // how high the dots bounce
    this.period = const Duration(milliseconds: 600),
    this.textStyle,
  });

  /// Optional text below the dots
  final String? message;

  /// Dot color (defaults to #FF8D29)
  final Color color;

  /// Diameter of each dot
  final double dotSize;

  /// Space between dots
  final double gap;

  /// Total widget height (helps center nicely in lists)
  final double height;

  /// Bounce height in pixels (vertical travel)
  final double amplitude;

  /// Full animation cycle duration
  final Duration period;

  /// Style for [message]
  final TextStyle? textStyle;

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void didUpdateWidget(covariant Loader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _ctrl.duration = widget.period;
      _ctrl
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildDot(double phase) {
    // phase values like 0.0, 0.25, 0.5 to stagger each dot
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        final dy = -widget.amplitude * math.sin(2 * math.pi * (t + phase));
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message;
    return SizedBox(
      height: widget.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dots row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0.00),                 // no delay
              SizedBox(width: widget.gap),
              _buildDot(0.25),                 // ~150ms if period is 600ms
              SizedBox(width: widget.gap),
              _buildDot(0.50),                 // ~300ms
            ],
          ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: widget.textStyle ??
                  const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
