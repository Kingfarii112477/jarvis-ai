import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';

/// A thin monospaced readout strip showing a live clock, connection
/// status, and whether hands-free wake-word mode is armed. Purely
/// decorative/informational — no interaction.
class HudStatusBar extends StatefulWidget {
  final bool wakeWordArmed;
  final bool connected;

  const HudStatusBar({
    super.key,
    required this.wakeWordArmed,
    this.connected = true,
  });

  @override
  State<HudStatusBar> createState() => _HudStatusBarState();
}

class _HudStatusBarState extends State<HudStatusBar> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: AppColors.textHud,
      fontSize: 11,
      letterSpacing: 1.1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _dotLabel(
          label: widget.connected ? 'LINK OK' : 'LINK DOWN',
          color: widget.connected ? AppColors.success : AppColors.error,
          style: style,
        ),
        Text(
          '${_twoDigits(_now.hour)}:${_twoDigits(_now.minute)}:${_twoDigits(_now.second)}',
          style: style,
        ),
        _dotLabel(
          label: widget.wakeWordArmed ? 'HANDS-FREE ARMED' : 'HANDS-FREE OFF',
          color: widget.wakeWordArmed ? AppColors.hudLine : AppColors.textSecondary,
          style: style,
        ),
      ],
    );
  }

  Widget _dotLabel({required String label, required Color color, required TextStyle style}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: style.copyWith(color: color)),
      ],
    );
  }
}
