import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/features/home/home_screen.dart';
import 'package:stream/features/library/library_screen.dart';
import 'package:stream/features/settings/settings_screen.dart';
import 'package:stream/core/theme/app_theme.dart';
import 'package:stream/core/providers/locale_provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: StreamApp()));
}

class StreamApp extends ConsumerWidget {
  const StreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Stream',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScaffold(),
      locale: localeState.locale,
      supportedLocales: const [Locale('en', 'US'), Locale('tr', 'TR')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages(AppLocalizations l10n) {
    return <Widget>[
      const HomeScreen(),
      Center(child: Text(l10n.navSearch)),
      const LibraryScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages(l10n);

    final width = MediaQuery.of(context).size.width;
    final bool useNavigationRail = width >= 800;

    if (useNavigationRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: Text(l10n.navHome),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.search),
                  label: Text(l10n.navSearch),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.video_library_outlined),
                  selectedIcon: const Icon(Icons.video_library),
                  label: Text(l10n.navLibrary),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: Text(l10n.navSettings),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: pages[_selectedIndex],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.navSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.video_library_outlined),
            selectedIcon: const Icon(Icons.video_library),
            label: l10n.navLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}