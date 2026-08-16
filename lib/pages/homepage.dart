import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../providers/station_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/esp32_client.dart';
import '../widgets/fuel_price_card.dart';
import '../widgets/slot_status_card.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  bool _isSavingPrice = false;

  Future<void> _handlePriceChange(String fuelType, double newPrice) async {
    setState(() => _isSavingPrice = true);
    try {
      await ref.read(stationProvider.notifier).setPrice(
        fuelType: fuelType,
        price: newPrice,
      );
    } on Esp32ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) {
        _showError('Could not reach the ESP32. Check the WiFi connection.');
      }
    } finally {
      if (mounted) setState(() => _isSavingPrice = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Could not update price'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(stationProvider);
    final theme = ref.watch(themeProvider);
    final accent = theme.accentColor.color;

    // NOTE: RefreshIndicator is a Material widget and is not exported by
    // flutter/cupertino.dart, so pull-to-refresh here uses the native
    // Cupertino equivalent, CupertinoSliverRefreshControl. That widget
    // must live inside a CustomScrollView's slivers list (it can't wrap
    // a plain ListView the way RefreshIndicator does), so the page body
    // below is a CustomScrollView with a single SliverList holding all
    // the same content that was previously inside the ListView.
    //
    // The page background stays transparent and follows the app's
    // theme (CupertinoPageScaffold picks up the ambient brightness set
    // in main.dart), matching the Settings page. The pump panels and
    // slot cards below are individually theme-aware too (via the
    // isDarkMode flag passed to each), so the whole page shifts
    // together when the person toggles dark mode rather than one part
    // of the UI staying fixed while another follows the toggle.
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(stationProvider.notifier).refreshNow(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Station branding line -- a small industrial-style
                // header that identifies which physical station this
                // app is controlling, echoing the signage on a real
                // pump island.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FUEL STATION CONTROL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fuel prices',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                    _ConnectionPill(isConnected: status.esp32Connected),
                  ],
                ),
                const SizedBox(height: 6),
                FuelPriceCard(
                  label: 'Diesel',
                  price: status.prices.diesel,
                  accentColor: accent,
                  isConnected: status.esp32Connected && !_isSavingPrice,
                  isDarkMode: theme.isDarkMode,
                  onPriceChanged: (p) => _handlePriceChange('diesel', p),
                ),
                const SizedBox(height: 12),
                FuelPriceCard(
                  label: 'Unleaded',
                  price: status.prices.unleaded,
                  accentColor: accent,
                  isConnected: status.esp32Connected && !_isSavingPrice,
                  isDarkMode: theme.isDarkMode,
                  onPriceChanged: (p) => _handlePriceChange('unleaded', p),
                ),
                const SizedBox(height: 12),
                FuelPriceCard(
                  label: 'Gasoline',
                  price: status.prices.gasoline,
                  accentColor: accent,
                  isConnected: status.esp32Connected && !_isSavingPrice,
                  isDarkMode: theme.isDarkMode,
                  onPriceChanged: (p) => _handlePriceChange('gasoline', p),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.square_grid_2x2,
                      size: 20,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Station slots',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status.esp32Connected
                      ? 'Live occupancy from the 4 IR sensors.'
                      : 'Sensors offline — status unknown until reconnected.',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: status.slots
                      .map((slot) => SlotStatusCard(
                    slot: slot,
                    isDarkMode: theme.isDarkMode,
                    accentColor: accent,
                  ))
                      .toList(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final bool isConnected;
  const _ConnectionPill({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color =
    isConnected ? CupertinoColors.activeGreen : CupertinoColors.systemGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Live' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}