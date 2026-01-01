import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/features/home/home_screen.dart';
import 'package:stream/features/search/search_screen.dart';
import 'package:stream/features/library/library_screen.dart';
import 'package:stream/features/settings/settings_screen.dart';
import 'package:stream/core/theme/app_theme.dart';
import 'package:stream/core/providers/locale_provider.dart';
import 'package:stream/core/providers/auth_provider.dart';
import 'package:stream/core/providers/library_provider.dart';

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

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;
  bool _syncInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAutoSync();
  }

  Future<void> _initializeAutoSync() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      ref.listenManual(authProvider, (_, next) {
        if (!next.isLoading && !_syncInitialized) {
          _performAutoSync(next);
        }
      });
    } else {
      _performAutoSync(authState);
    }
  }

  Future<void> _performAutoSync(AuthState authState) async {
    if (_syncInitialized) return;
    _syncInitialized = true;

    final syncService = authState.syncService;
    if (syncService == null) return;

    try {
      debugPrint('Auto-sync: Starting...');
      final libraryNotifier = ref.read(libraryProvider.notifier);
      libraryNotifier.setSyncService(syncService);
      
      await libraryNotifier.processPendingSync();
      await libraryNotifier.syncFromRemote();
      
      debugPrint('Auto-sync: Complete');
    } catch (e) {
      debugPrint('Auto-sync error: $e');
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return const <Widget>[
      HomeScreen(),
      SearchScreen(),
      LibraryScreen(),
      SettingsScreen(),
    ];
  }

  List<_NavItem> _buildNavItems(AppLocalizations l10n) {
    return [
      _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome),
      _NavItem(icon: Icons.search_outlined, selectedIcon: Icons.search, label: l10n.navSearch),
      _NavItem(icon: Icons.video_library_outlined, selectedIcon: Icons.video_library, label: l10n.navLibrary),
      _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: l10n.navSettings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages();
    final navItems = _buildNavItems(l10n);

    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(navItems, l10n),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildMobileNavbar(navItems),
    );
  }

  Widget _buildDesktopSidebar(List<_NavItem> navItems, AppLocalizations l10n) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(Icons.play_arrow, color: AppTheme.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Nav Items
          ...List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = _selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onDestinationSelected(index),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentDim : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected ? AppTheme.accent : Colors.grey[400],
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.accent : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileNavbar(List<_NavItem> navItems) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => _onDestinationSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 20 : 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected ? AppTheme.accent : Colors.grey[500],
                        size: 22,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: isSelected
                            ? Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}