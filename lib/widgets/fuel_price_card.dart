import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Displays one fuel type's current price styled like a physical pump
/// dispenser readout: a matte panel, a color-coded accent bar for the
/// fuel type, and a monospaced peso amount. The whole thing sits inside
/// a [GlassCard] so it still catches the liquid-glass refraction at its
/// edges, while the inner panel stays a solid surface for contrast and
/// legibility (the way an actual pump display would).
///
/// The panel follows the app's light/dark mode setting via
/// [isDarkMode] rather than staying permanently black — in dark mode it
/// reads as a lit display against a darker page; in light mode it's a
/// light gray card, keeping the same relative contrast step against
/// whatever the page background is.
///
/// Tapping the price opens an edit dialog with a number field;
/// submitting calls [onPriceChanged], which the caller wires to the
/// station provider's setPrice (which in turn pushes to the ESP32 and
/// the physical TM1637 display).
///
/// NOTE: this uses CupertinoAlertDialog + CupertinoTextField (core
/// Flutter SDK) rather than GlassDialog/GlassTextField. Those two glass
/// widgets exist in liquid_glass_widgets, but this package ships several
/// releases per day and its exact constructor signatures (title as
/// String? vs Widget, hintText support, action item types) kept
/// changing between the versions checked while building this file. The
/// Cupertino versions are part of the stable Flutter SDK and won't
/// break under you the same way. If you'd like the glass-styled
/// version, check the current GlassDialog/GlassTextField signatures in
/// your installed package version first (Cmd/Ctrl+click through from
/// the import) and swap these in.
class FuelPriceCard extends StatelessWidget {
  final String label;
  final double price;
  final Color accentColor;
  final bool isConnected;
  final bool isDarkMode;
  final ValueChanged<double> onPriceChanged;

  const FuelPriceCard({
    super.key,
    required this.label,
    required this.price,
    required this.accentColor,
    required this.isConnected,
    required this.isDarkMode,
    required this.onPriceChanged,
  });

  /// The pump-panel background follows the app's theme: a solid dark
  /// surface in dark mode (reading as a lit display), a solid light
  /// gray surface in light mode. Either way it's one contrast step
  /// lighter than the page background it sits on, so the panel reads
  /// as a raised card rather than blending into the page.
  Color get _panelColor =>
      isDarkMode ? const Color(0xFF1C1D22) : const Color(0xFFEDEDED);
  Color get _panelBorder =>
      accentColor.withValues(alpha: isDarkMode ? 0.45 : 0.55);

  /// Foreground colors on the panel flip between white-based (dark
  /// mode) and black-based (light mode) washes at matching opacities,
  /// so text/icon contrast against the panel stays consistent in both
  /// themes rather than going invisible in one of them.
  Color get _labelColor =>
      isDarkMode ? const Color(0x80FFFFFF) : const Color(0x80000000);
  Color get _priceColorConnected =>
      isDarkMode ? CupertinoColors.white : CupertinoColors.black;
  Color get _priceColorDisconnected =>
      isDarkMode ? const Color(0x4DFFFFFF) : const Color(0x4D000000);
  Color get _iconCircleColorConnected =>
      isDarkMode ? const Color(0x14FFFFFF) : const Color(0x14000000);
  Color get _iconCircleColorDisconnected =>
      isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x0A000000);
  Color get _iconColorConnected =>
      isDarkMode ? const Color(0x99FFFFFF) : const Color(0x99000000);
  Color get _iconColorDisconnected =>
      isDarkMode ? const Color(0x4DFFFFFF) : const Color(0x4D000000);

  Future<void> _openEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: price.toStringAsFixed(2));
    String? errorText;

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: Text('Set $label price'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoTextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      placeholder: 'e.g. 65.75',
                      autofocus: true,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'Range: 0.00 to 99.99 (display shows 2 decimals)',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final parsed = double.tryParse(controller.text.trim());
                    if (parsed == null) {
                      setDialogState(() => errorText = 'Enter a valid number');
                      return;
                    }
                    if (parsed < 0 || parsed > 99.99) {
                      setDialogState(
                            () => errorText = 'Must be between 0.00 and 99.99',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    onPriceChanged(parsed);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Formats the price for display. When disconnected, shows a dashed
  /// placeholder rather than the last-known price — a stale-looking
  /// ₱0.00 would read as "fuel is free," which is worse than admitting
  /// the data isn't current.
  String get _displayPrice =>
      isConnected ? '\u20b1${price.toStringAsFixed(2)}' : '\u20b1--.--';

  @override
  Widget build(BuildContext context) {
    // GlassCard does not expose an onTap parameter in the current
    // package version, so the tap target wraps the card from outside
    // via GestureDetector instead. GlassCard here is the outer glass
    // surface (catches refraction at the edges); the dark pump panel is
    // a plain Container nested inside it, matching the "glass is a
    // platter, not a wrapper" rule from the package docs — GlassCard
    // holds plain content (Container, Text, Icon), never another
    // refractive glass widget.
    return GestureDetector(
      onTap: isConnected ? () => _openEditDialog(context) : null,
      child: GlassCard(
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _panelBorder, width: 1),
          ),
          child: Row(
            children: [
              // Color-coded accent bar identifying the fuel type, like
              // the colored stripe on a physical pump nozzle/display.
              Container(
                width: 4,
                height: 34,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: _labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayPrice,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
                        color: isConnected
                            ? _priceColorConnected
                            : _priceColorDisconnected,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? _iconCircleColorConnected
                      : _iconCircleColorDisconnected,
                ),
                child: Icon(
                  isConnected
                      ? CupertinoIcons.pencil
                      : CupertinoIcons.wifi_slash,
                  color: isConnected
                      ? _iconColorConnected
                      : _iconColorDisconnected,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}