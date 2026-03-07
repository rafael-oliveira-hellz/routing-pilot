import 'package:flutter/material.dart';

/// Marcador com efeito pulsante (ex.: radar / BLITZ). Repete escala 1.0 → 1.4 → 1.0.
class PulsatingMarker extends StatefulWidget {
  const PulsatingMarker({
    super.key,
    required this.child,
    this.size = 40,
  });

  final Widget child;
  final double size;

  @override
  State<PulsatingMarker> createState() => _PulsatingMarkerState();
}

class _PulsatingMarkerState extends State<PulsatingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: widget.child,
          ),
        );
      },
    );
  }
}
