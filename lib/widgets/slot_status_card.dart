import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../models/station_status.dart';

/// Compact card showing one gasoline slot's occupancy, driven by the
/// corresponding IR sensor. Shown in a grid on the homepage. Styled
/// like a parking-bay indicator: a colored icon badge for status, the
/// slot number as a large watermark digit in the corner, and the
/// status word below.
///
/// Like [FuelPriceCard], this sits on a solid panel that follows the
/// app's light/dark mode setting via [isDarkMode], so all four slot
/// cards read as one coherent piece of station signage in either
/// theme, at the same relative contrast step against the page.
///
/// The card border and watermark number are tinted with [accentColor]
/// (the same accent picked in Settings > Appearance) rather than a
/// neutral black/white wash — a saturated tinted border is easier to
/// pick out against both a dark and a light panel than a desaturated
/// gray one at the same opacity, so this both fixes low-contrast
/// borders and ties the accent color setting to more of the UI.
class SlotStatusCard extends StatelessWidget {
  final SlotInfo slot;
  final bool isDarkMode;
  final Color accentColor;

  const SlotStatusCard({
    super.key,
    required this.slot,
    required this.isDarkMode,
    required this.accentColor,
  });

  Color get _panelColor =>
      isDarkMode ? const Color(0xFF16171A) : const Color(0xFFF0F0F0);

  /// Border uses the accent color at a strength that reads clearly as
  /// a boundary in both themes without turning the whole card into a
  /// colored block. 45% in dark mode (accent colors read a bit
  /// muddier against dark panels at low opacity), 55% in light mode.
  Color get _panelBorder => accentColor.withValues(alpha: isDarkMode ? 0.45 : 0.55);

  /// Watermark number: tinted with the accent color so it reads as
  /// part of the same visual system as the border, at a low enough
  /// opacity to stay behind the status icon/text in visual weight.
  Color get _watermarkColor => accentColor.withValues(alpha: isDarkMode ? 0.35 : 0.28);
  Color get _labelColor =>
      isDarkMode ? const Color(0x80FFFFFF) : const Color(0x80000000);
  Color get _sensorIssueColor =>
      isDarkMode ? const Color(0x4DFFFFFF) : const Color(0x4D000000);
  Color get _unknownStatusColor =>
      isDarkMode ? const Color(0x80FFFFFF) : const Color(0x80000000);

  @override
  Widget build(BuildContext context) {
    final bool sensorHealthy = slot.sensorStatus == SensorStatus.connected;

    // If the sensor itself isn't healthy, we cannot trust the occupancy
    // reading -- show "unknown" rather than a possibly-wrong occupied/
    // unoccupied state.
    final String statusLabel = !sensorHealthy
        ? 'Unknown'
        : (slot.occupied ? 'Occupied' : 'Available');

    // Unknown state is deliberately desaturated -- a muted gray rather
    // than the red/green used for confirmed occupied/available, so it
    // doesn't visually compete with cards that have trustworthy data.
    // The exact gray flips between a white-based and black-based wash
    // depending on the theme, same as the rest of the panel's text.
    final Color statusColor = !sensorHealthy
        ? _unknownStatusColor
        : (slot.occupied
        ? CupertinoColors.systemRed
        : CupertinoColors.activeGreen);

    final IconData statusIcon = !sensorHealthy
        ? CupertinoIcons.question_circle
        : (slot.occupied ? CupertinoIcons.car_detailed : CupertinoIcons.checkmark_circle);

    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panelColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _panelBorder, width: 1),
        ),
        child: Stack(
          children: [
            // Watermark slot number in the top-right corner, kept subtle
            // so it reads as ambient station signage rather than
            // competing with the status text.
            Positioned(
              top: -6,
              right: -2,
              child: Text(
                '${slot.id}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: _watermarkColor,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 19),
                ),
                const SizedBox(height: 10),
                Text(
                  slot.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: _labelColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (!sensorHealthy) ...[
                  const SizedBox(height: 2),
                  Text(
                    'sensor issue',
                    style: TextStyle(
                      fontSize: 11,
                      color: _sensorIssueColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}