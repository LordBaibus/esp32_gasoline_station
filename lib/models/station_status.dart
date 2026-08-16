/// Data models mirroring the ESP32 firmware's /api/status JSON response.
///
/// Kept as plain immutable classes (no codegen) to match the simple,
/// dependency-light style already used across the project's other apps.

enum SensorStatus { connected, disconnected, faulty }

SensorStatus sensorStatusFromString(String? raw) {
  switch (raw) {
    case 'connected':
      return SensorStatus.connected;
    case 'faulty':
      return SensorStatus.faulty;
    default:
      return SensorStatus.disconnected;
  }
}

class FuelPrices {
  final double diesel;
  final double unleaded;
  final double gasoline;

  const FuelPrices({
    required this.diesel,
    required this.unleaded,
    required this.gasoline,
  });

  factory FuelPrices.fromJson(Map<String, dynamic> json) {
    return FuelPrices(
      diesel: (json['diesel'] as num?)?.toDouble() ?? 0.0,
      unleaded: (json['unleaded'] as num?)?.toDouble() ?? 0.0,
      gasoline: (json['gasoline'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory FuelPrices.zero() =>
      const FuelPrices(diesel: 0, unleaded: 0, gasoline: 0);
}

class DisplayStatusSet {
  final SensorStatus diesel;
  final SensorStatus unleaded;
  final SensorStatus gasoline;

  const DisplayStatusSet({
    required this.diesel,
    required this.unleaded,
    required this.gasoline,
  });

  factory DisplayStatusSet.fromJson(Map<String, dynamic> json) {
    return DisplayStatusSet(
      diesel: sensorStatusFromString(json['diesel'] as String?),
      unleaded: sensorStatusFromString(json['unleaded'] as String?),
      gasoline: sensorStatusFromString(json['gasoline'] as String?),
    );
  }

  factory DisplayStatusSet.allDisconnected() => const DisplayStatusSet(
    diesel: SensorStatus.disconnected,
    unleaded: SensorStatus.disconnected,
    gasoline: SensorStatus.disconnected,
  );
}

class SlotInfo {
  final int id;
  final String name;
  final bool occupied;
  final SensorStatus sensorStatus;

  const SlotInfo({
    required this.id,
    required this.name,
    required this.occupied,
    required this.sensorStatus,
  });

  factory SlotInfo.fromJson(Map<String, dynamic> json) {
    return SlotInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Slot',
      occupied: json['occupied'] as bool? ?? false,
      sensorStatus: sensorStatusFromString(json['sensor_status'] as String?),
    );
  }
}

/// Full snapshot of the station as returned by GET /api/status.
class StationStatus {
  final bool esp32Connected;
  final FuelPrices prices;
  final DisplayStatusSet displays;
  final List<SlotInfo> slots;
  final int uptimeMs;
  final DateTime fetchedAt;

  const StationStatus({
    required this.esp32Connected,
    required this.prices,
    required this.displays,
    required this.slots,
    required this.uptimeMs,
    required this.fetchedAt,
  });

  factory StationStatus.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    return StationStatus(
      esp32Connected: json['esp32_connected'] as bool? ?? false,
      prices: FuelPrices.fromJson(
        json['prices'] as Map<String, dynamic>? ?? {},
      ),
      displays: DisplayStatusSet.fromJson(
        json['displays'] as Map<String, dynamic>? ?? {},
      ),
      slots: slotsJson
          .map((s) => SlotInfo.fromJson(s as Map<String, dynamic>))
          .toList(),
      uptimeMs: (json['uptime_ms'] as num?)?.toInt() ?? 0,
      fetchedAt: DateTime.now(),
    );
  }

  /// Represents a station we have not yet successfully reached — every
  /// panel should render as disconnected/unknown rather than fabricating
  /// plausible-looking placeholder data.
  factory StationStatus.disconnected() {
    return StationStatus(
      esp32Connected: false,
      prices: FuelPrices.zero(),
      displays: DisplayStatusSet.allDisconnected(),
      slots: List.generate(
        4,
            (i) => SlotInfo(
          id: i + 1,
          name: 'Slot ${i + 1}',
          occupied: false,
          sensorStatus: SensorStatus.disconnected,
        ),
      ),
      uptimeMs: 0,
      fetchedAt: DateTime.now(),
    );
  }
}