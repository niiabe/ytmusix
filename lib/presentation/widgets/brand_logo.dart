import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const BrandLogo({
    super.key,
    this.size = 80,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/brand/icon.png',
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
        ),
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.5,
          color: Colors.white24,
        ),
      ),
    );

    if (backgroundColor == null && borderRadius == null) {
      return image;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}
