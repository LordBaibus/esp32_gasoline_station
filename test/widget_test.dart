// Basic smoke test for the gasoline station companion app.
//
// This replaces the default counter-app test that `flutter create`
// generates automatically -- that template referenced a package name
// and a MyApp shape from a different project and doesn't match this
// app's actual structure (ProviderScope + LiquidGlassWidgets.wrap +
// the tab-based Homepage/Settings scaffold).
//
// NOTE ON NETWORK CALLS IN TESTS: MyApp's build() creates the
// StationNotifier via Riverpod, and that notifier immediately starts
// polling GET /api/status on the ESP32's AP (192.168.4.1) via
// Timer.periodic. In the test environment there is no real network
// and no ESP32, so that call will fail -- which is fine, because
// Esp32Client.fetchStatus()'s failure path is caught in
// StationNotifier._pollOnce() and falls back to
// StationStatus.disconnected() rather than throwing. The app should
// render normally in a "disconnected" state. `tester.pump()` (rather
// than `pumpAndSettle()`) is used below specifically to avoid waiting
// on that timer-driven polling loop, which never truly "settles"
// since it repeats every 1.5s.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:gasoline_station_app/main.dart';

void main() {
  testWidgets('App launches and shows the homepage', (WidgetTester tester) async {
    // Mirrors the real startup sequence in main.dart: ProviderScope
    // wraps the app for Riverpod state, and LiquidGlassWidgets.wrap
    // installs the glass rendering layer that GlassScaffold/GlassCard
    // depend on. Skipping either wrapper here would make the widget
    // tree crash immediately, not just fail to look right.
    await tester.pumpWidget(
      ProviderScope(
        child: LiquidGlassWidgets.wrap(child: const MyApp()),
      ),
    );

    // A single pump (not pumpAndSettle) lets the first frame and any
    // immediately-scheduled microtasks complete without waiting on the
    // station provider's recurring poll timer.
    await tester.pump();

    // Smoke-level assertion: the homepage's price section heading
    // should be visible after launch, confirming the app didn't crash
    // during startup and landed on the expected first tab.
    expect(find.text('Fuel prices'), findsOneWidget);
  });
}