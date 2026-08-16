import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../models/station_status.dart';
import '../providers/station_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/status_row.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  @override
  Widget build(BuildContext context) {
    final status = ref.watch(stationProvider);
    final theme = ref.watch(themeProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            'STATION DIAGNOSTICS'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),

          // --- ESP32 connection ---
          const _SectionLabel(icon: CupertinoIcons.device_desktop, text: 'Device'),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: StatusRow(
              icon: CupertinoIcons.wifi,
              label: 'ESP32 controller',
              status: status.esp32Connected
                  ? SensorStatus.connected
                  : SensorStatus.disconnected,
            ),
          ),

          const SizedBox(height: 24),

          // --- TM1637 displays ---
          const _SectionLabel(
            icon: CupertinoIcons.number,
            text: 'Price displays',
          ),
          const SizedBox(height: 4),
          const Text(
            'These reflect firmware write confirmations, not a hardware '
                'readback — TM1637 has no return signal, so "connected" means '
                'the ESP32 successfully sent data to that display.',
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                StatusRow(
                  icon: CupertinoIcons.square_fill,
                  label: 'Diesel',
                  status: status.displays.diesel,
                ),
                const _RowDivider(),
                StatusRow(
                  icon: CupertinoIcons.square_fill,
                  label: 'Unleaded',
                  status: status.displays.unleaded,
                ),
                const _RowDivider(),
                StatusRow(
                  icon: CupertinoIcons.square_fill,
                  label: 'Gasoline',
                  status: status.displays.gasoline,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- IR sensors ---
          const _SectionLabel(
            icon: CupertinoIcons.dot_radiowaves_left_right,
            text: 'Slot sensors',
          ),
          const SizedBox(height: 4),
          const Text(
            '"Faulty" means a sensor has not changed reading for a while '
                'even though the others are active — a heuristic, not a '
                'hardware self-test.',
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < status.slots.length; i++) ...[
                  if (i > 0) const _RowDivider(),
                  StatusRow(
                    icon: CupertinoIcons.square_grid_2x2,
                    label: status.slots[i].name,
                    status: status.slots[i].sensorStatus,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Theme ---
          // NOTE: liquid_glass_widgets' own docs specify GlassSwitch must
          // NOT be nested inside GlassCard/GlassContainer — interactive
          // glass controls already render their own surface via
          // backgroundColor, and an outer glass container degrades the
          // refraction by design. So the dark-mode row below is plain
          // (Text + GlassSwitch as siblings, no wrapping GlassCard),
          // while the accent-color card uses only plain Flutter widgets
          // inside GlassCard, which the docs explicitly allow.
          const _SectionLabel(
            icon: CupertinoIcons.paintbrush,
            text: 'Appearance',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark mode', style: TextStyle(fontSize: 15)),
                GlassSwitch(
                  value: theme.isDarkMode,
                  onChanged: (v) =>
                      ref.read(themeProvider.notifier).setDarkMode(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accent color',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppAccentColor.values.map((c) {
                    final bool selected = c == theme.accentColor;
                    return GestureDetector(
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setAccentColor(c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.color,
                          border: selected
                              ? Border.all(
                            color: CupertinoColors.label
                                .resolveFrom(context),
                            width: 3,
                          )
                              : null,
                        ),
                        child: selected
                            ? const Icon(
                          CupertinoIcons.checkmark,
                          color: CupertinoColors.white,
                          size: 18,
                        )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }
}