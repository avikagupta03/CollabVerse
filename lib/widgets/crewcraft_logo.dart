import 'package:flutter/material.dart';

/// Branded header widget that recreates the CrewCraft AI logomark without
/// relying on raster assets.
class CrewCraftLogo extends StatelessWidget {
  const CrewCraftLogo({super.key, this.size = 72, this.showLabel = true});

  /// Overall height/width of the hexagon portion of the logo.
  final double size;

  /// Whether to paint the "CrewCraft AI" wordmark beside the icon.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final targetSize = size.clamp(32, 160);
    final calculatedFontSize = targetSize * 0.55;
    final titleStyle =
        textTheme.headlineSmall?.copyWith(
          color: const Color(0xFF111927),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          fontSize: calculatedFontSize,
        ) ??
        TextStyle(
          color: const Color(0xFF111927),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          fontSize: calculatedFontSize,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HexagonBadge(size: size),
        if (showLabel) ...[
          SizedBox(width: size * 0.4),
          RichText(
            text: TextSpan(
              text: 'CrewCraft',
              style: titleStyle,
              children: const [
                TextSpan(text: ' '),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    color: Color(0xFF1C7CF3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HexagonBadge extends StatelessWidget {
  const _HexagonBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: ClipPath(
        clipper: _HexagonClipper(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1C7CF3), Color(0xFF41C3FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(Icons.hub, size: size * 0.45, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final halfHeight = height / 2;
    return Path()
      ..moveTo(width * 0.25, 0)
      ..lineTo(width * 0.75, 0)
      ..lineTo(width, halfHeight)
      ..lineTo(width * 0.75, height)
      ..lineTo(width * 0.25, height)
      ..lineTo(0, halfHeight)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
