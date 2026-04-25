import 'package:flutter/material.dart';
import '../../services/screen_shake_service.dart';

/// Wraps any widget and applies screen shake offset based on [ScreenShakeService].
/// Place this around the game board container for the full shake effect.
class ScreenShakeWrapper extends StatefulWidget {
  final Widget child;
  const ScreenShakeWrapper({super.key, required this.child});

  @override
  State<ScreenShakeWrapper> createState() => _ScreenShakeWrapperState();
}

class _ScreenShakeWrapperState extends State<ScreenShakeWrapper> {
  @override
  void initState() {
    super.initState();
    ScreenShakeService().addListener(_onShake);
  }

  @override
  void dispose() {
    ScreenShakeService().removeListener(_onShake);
    super.dispose();
  }

  void _onShake() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final offset = ScreenShakeService().shakeOffset;
    return Transform.translate(
      offset: offset,
      child: widget.child,
    );
  }
}
