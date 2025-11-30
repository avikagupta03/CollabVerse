import 'package:flutter/material.dart';

class AnimatedLoadingButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const AnimatedLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  State<AnimatedLoadingButton> createState() => _AnimatedLoadingButtonState();
}

class _AnimatedLoadingButtonState extends State<AnimatedLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? Colors.deepPurple,
          minimumSize: const Size(double.infinity, 50),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          disabledBackgroundColor:
              (widget.backgroundColor ?? Colors.deepPurple).withOpacity(0.6),
        ),
        child: widget.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
