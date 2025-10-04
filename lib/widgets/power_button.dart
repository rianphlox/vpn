import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PowerButton extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const PowerButton({
    Key? key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isConnected
                      ? [
                          const Color(0xFF4CAF50),
                          const Color(0xFF388E3C),
                        ]
                      : [
                          const Color(0xFF4FC3F7),
                          const Color(0xFF29B6F6),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isConnected
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF4FC3F7))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.isConnecting
                  ? const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    )
                  : Icon(
                      widget.isConnected
                          ? CupertinoIcons.power
                          : CupertinoIcons.play_fill,
                      size: 48,
                      color: Colors.white,
                    ),
            ),
          );
        },
      ),
    );
  }
}