import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class AnimatedCircularProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final String? centerText;

  const AnimatedCircularProgress({
    super.key,
    required this.value,
    this.size = 80,
    required this.color,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 8.0,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          // Background track
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(backgroundColor.withOpacity(0.1)),
            ),
          ),
          // Animated progress
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: value),
            duration: AppDurations.long,
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return SizedBox(
                height: size,
                width: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
          // Center text
          if (centerText != null)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: value),
                duration: AppDurations.long,
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Text(
                    '${(value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedWaveProgress extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color color;

  const AnimatedWaveProgress({
    super.key,
    required this.value,
    this.height = 100,
    required this.color,
  });

  @override
  State<AnimatedWaveProgress> createState() => _AnimatedWaveProgressState();
}

class _AnimatedWaveProgressState extends State<AnimatedWaveProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipPath(
                clipper: WaveClipper(
                  animation: _controller,
                  value: widget.value,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Text(
              '${(widget.value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final Animation<double> animation;
  final double value;

  WaveClipper({required this.animation, required this.value});

  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;
    
    // Where the wave top should be (inverted because 0 is top of screen)
    final waveTop = height * (1 - value);
    final waveHeight = height * 0.05; // Height of the wave
    
    path.moveTo(0, height);
    path.lineTo(0, waveTop);
    
    // Draw the wave
    for (var i = 0.0; i < width; i++) {
      path.lineTo(
        i,
        waveTop + sin((i / width * 2 * pi) + (animation.value * 2 * pi)) * waveHeight,
      );
    }
    
    path.lineTo(width, waveTop);
    path.lineTo(width, height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
} 