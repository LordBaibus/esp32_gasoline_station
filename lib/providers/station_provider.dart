import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station_status.dart';
import 'esp32_client.dart';

/// Polling state notifier for live station data (prices, slot occupancy,
/// sensor/display health). Uses Riverpod 3.x's Notifier API to match the
/// pattern already established in the arcade machine's companion app.
///
/// The notifier owns its own Timer.periodic loop rather than relying on
/// a stream provider, so pages can trigger an immediate manual refresh
/// (e.g. pull-to-refresh, or right after setting a price) without waiting
/// for the next scheduled tick.
class StationNotifier extends Notifier<StationStatus> {
  Timer? _pollTimer;
  bool _isDisposed = false;

  @override
  StationStatus build() {
    ref.onDispose(() {
      _isDisposed = true;
      _pollTimer?.cancel();
    });
    _startPolling();
    return StationStatus.disconnected();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Fire once immediately, then on the regular interval.
    _pollOnce();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (_isDisposed) return;
    try {
      final client = ref.read(esp32ClientProvider);
      final result = await client.fetchStatus();
      if (!_isDisposed) {
        state = result;
      }
    } catch (_) {
      // Connection failed (ESP32 off, wrong WiFi, out of range, etc).
      // Reflect disconnected state rather than leaving stale "connected"
      // data on screen — a stale-looking "occupied" slot after the
      // device drops off WiFi would be actively misleading.
      if (!_isDisposed) {
        state = StationStatus.disconnected();
      }
    }
  }

  /// Manual refresh, for pull-to-refresh gestures.
  Future<void> refreshNow() => _pollOnce();

  /// Sets a fuel price via the REST API, then immediately refreshes so
  /// the UI reflects the ESP32-confirmed value rather than optimistically
  /// showing what we asked for (in case the device clamped/rejected it).
  Future<void> setPrice({
    required String fuelType,
    required double price,
  }) async {
    final client = ref.read(esp32ClientProvider);
    await client.setPrice(fuelType: fuelType, price: price);
    await _pollOnce();
  }
}

final stationProvider = NotifierProvider<StationNotifier, StationStatus>(
  StationNotifier.new,
);