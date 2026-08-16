import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/station_status.dart';

/// Base URL of the ESP32 REST API. Matches the AP's default gateway IP
/// set in the firmware (AP_LOCAL_IP = 192.168.4.1). If you change the
/// AP's static IP in the firmware, update this constant to match.
const String esp32BaseUrl = 'http://192.168.4.1';

/// How often the homepage/settings pages poll GET /api/status.
/// 1500ms was chosen as a balance between "feels live" and not hammering
/// the ESP32's single-core async web server with requests.
const Duration pollInterval = Duration(milliseconds: 1500);

/// Timeout for individual HTTP calls. Kept short because on a local AP
/// a slow response almost always means the ESP32 is unreachable, not
/// genuinely slow — no reason to make the user wait.
const Duration requestTimeout = Duration(seconds: 3);

class Esp32Client {
  final http.Client _http = http.Client();

  Future<StationStatus> fetchStatus() async {
    final uri = Uri.parse('$esp32BaseUrl/api/status');
    final response = await _http.get(uri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Esp32ApiException(
        'Status request failed with code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
    jsonDecode(response.body) as Map<String, dynamic>;
    return StationStatus.fromJson(json);
  }

  /// Sets a single fuel price. Returns the updated prices from the ESP32
  /// on success (so the UI reflects exactly what the device persisted,
  /// not just what we asked for).
  Future<FuelPrices> setPrice({
    required String fuelType,
    required double price,
  }) async {
    final uri = Uri.parse('$esp32BaseUrl/api/prices');
    final response = await _http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fuelType': fuelType, 'price': price}),
    )
        .timeout(requestTimeout);

    final Map<String, dynamic> json =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      final String errorMsg = json['error'] as String? ?? 'Unknown error';
      throw Esp32ApiException(errorMsg);
    }

    return FuelPrices.fromJson(json['prices'] as Map<String, dynamic>);
  }

  void dispose() => _http.close();
}

class Esp32ApiException implements Exception {
  final String message;
  Esp32ApiException(this.message);
  @override
  String toString() => message;
}

final esp32ClientProvider = Provider<Esp32Client>((ref) {
  final client = Esp32Client();
  ref.onDispose(client.dispose);
  return client;
});