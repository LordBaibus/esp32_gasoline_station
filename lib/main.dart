import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'pages/homepage.dart';
import 'pages/settings.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(
    ProviderScope(
      child: LiquidGlassWidgets.wrap(child: const MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  int selectedIndex = 0;

  static const List<Widget> _pages = [
    Homepage(),
    Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: theme.isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: theme.accentColor.color,
      ),
      home: GlassScaffold(
        body: SafeArea(child: _pages[selectedIndex]),
        bottomBar: GlassTabBar.bottom(
          tabs: const [
            GlassTab(icon: Icon(CupertinoIcons.home)),
            GlassTab(icon: Icon(CupertinoIcons.settings)),
          ],
          selectedIndex: selectedIndex,
          // Fixed: the original code reassigned the callback's `tab`
          // parameter instead of updating `selectedIndex`, so tapping a
          // tab never actually changed which page was shown.
          onTabSelected: (tab) {
            setState(() {
              selectedIndex = tab;
            });
          },
        ),
      ),
    );
  }
}