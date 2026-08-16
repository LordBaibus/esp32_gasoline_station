import 'package:flutter/cupertino.dart';
import '../models/station_status.dart';

/// A single status row: optional leading icon, label, and a pill-style
/// status indicator on the right. Used for ESP32 connection, TM1637
/// displays, and IR sensors on the settings page. Kept as a plain
/// CupertinoListTile-style row per the liquid_glass_widgets docs' own
/// guidance for settings screens ("use CupertinoListTile or standard
/// Flutter containers for the rows").
class StatusRow extends StatelessWidget {
  final String label;
  final SensorStatus status;
  final IconData? icon;

  const StatusRow({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  ({Color color, String text}) get _display {
    switch (status) {
      case SensorStatus.connected:
        return (color: CupertinoColors.activeGreen, text: 'Connected');
      case SensorStatus.faulty:
        return (color: CupertinoColors.systemOrange, text: 'Faulty');
      case SensorStatus.disconnected:
        return (color: CupertinoColors.systemGrey, text: 'Disconnected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: d.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.color,
                  ),
                ),
                Text(
                  d.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: d.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}