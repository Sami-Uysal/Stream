import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/providers/locale_provider.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/core/providers/auth_provider.dart';
import 'package:stream/core/services/trakt_auth_service.dart';
import 'package:stream/core/services/simkl_auth_service.dart';
import 'package:stream/core/services/sync_service.dart';
import 'package:stream/core/theme/app_theme.dart';

class _SyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final _syncingProvider = NotifierProvider<_SyncingNotifier, bool>(_SyncingNotifier.new);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final libraryState = ref.watch(libraryProvider);
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(l10n.settingsTitle),
          ),
          
          // App Info Section
          SliverToBoxAdapter(
            child: _buildAppInfoCard(context, libraryState),
          ),
          
          // Accounts Section (Trakt & Simkl)
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Hesaplar', Icons.account_circle),
          ),
          SliverToBoxAdapter(
            child: _buildAccountsSection(context, ref, authState),
          ),
          
          // Language & Region Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Dil ve Bölge', Icons.language),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.translate,
                  iconColor: AppTheme.tvBadge,
                  title: l10n.settingsLanguage,
                  subtitle: localeState.locale.languageCode == 'tr' ? 'Türkçe' : 'English',
                  onTap: () => _showLanguagePicker(context, localeNotifier, localeState),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.public,
                  iconColor: AppTheme.statusCompleted,
                  title: l10n.settingsContentRegion,
                  subtitle: _getRegionName(localeState.region, l10n),
                  onTap: () => _showRegionPicker(context, localeNotifier, localeState, l10n),
                ),
              ],
            ),
          ),
          
          // Appearance Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Görünüm', Icons.palette),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.dark_mode,
                  iconColor: AppTheme.movieBadge,
                  title: 'Tema',
                  subtitle: 'Koyu',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Text(
                      'Varsayılan',
                      style: TextStyle(color: AppTheme.accent, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Storage Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Depolama', Icons.storage),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.cached,
                  iconColor: AppTheme.statusOnHold,
                  title: 'Önbellek',
                  subtitle: 'Resim ve veriler',
                  onTap: () => _showClearCacheDialog(context, l10n),
                ),
              ],
            ),
          ),
          
          // Danger Zone Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Tehlike Bölgesi', Icons.warning_amber),
          ),
          SliverToBoxAdapter(
            child: _buildDangerCard(
              context,
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.delete_forever,
                  iconColor: AppTheme.statusDropped,
                  title: l10n.clearCache,
                  subtitle: 'Tüm önbelleği temizle',
                  onTap: () => _showClearCacheDialog(context, l10n),
                  isDanger: true,
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.delete_sweep,
                  iconColor: AppTheme.statusDropped,
                  title: 'Kütüphaneyi Sıfırla',
                  subtitle: 'Tüm kayıtlı içerikleri sil',
                  onTap: () => _showResetLibraryDialog(context, ref, l10n),
                  isDanger: true,
                ),
              ],
            ),
          ),
          
          // About Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Hakkında', Icons.info_outline),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.code,
                  iconColor: Colors.grey,
                  title: 'Versiyon',
                  subtitle: '1.0.0',
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.api,
                  iconColor: Colors.grey,
                  title: 'API',
                  subtitle: 'TMDB',
                ),
              ],
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, LibraryState libraryState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent.withAlpha(30),
            AppTheme.movieBadge.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: AppTheme.accent.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(50),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: const Icon(Icons.play_arrow, color: AppTheme.accent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nexus Stream',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${libraryState.items.length} kayıtlı içerik',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSection(BuildContext context, WidgetRef ref, AuthState authState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        children: [
          // Trakt Account
          _buildAccountTile(
            context: context,
            ref: ref,
            serviceName: 'Trakt',
            serviceIcon: Icons.movie_filter,
            iconColor: const Color(0xFFED1C24), // Trakt red
            isConnected: authState.isTraktConnected,
            username: authState.traktUser?.username,
            isLoading: authState.isLoading,
            isConfigured: TraktAuthService.isConfigured,
            onConnect: () => ref.read(authProvider.notifier).connectTrakt(),
            onDisconnect: () => _showDisconnectDialog(
              context, 
              ref, 
              'Trakt', 
              () => ref.read(authProvider.notifier).disconnectTrakt(),
            ),
          ),
          const Divider(height: 1, indent: 56),
          // Simkl Account
          _buildAccountTile(
            context: context,
            ref: ref,
            serviceName: 'Simkl',
            serviceIcon: Icons.play_circle_filled,
            iconColor: const Color(0xFF0099FF),
            isConnected: authState.isSimklConnected,
            username: authState.simklUser?.username,
            isLoading: authState.isLoading,
            isConfigured: SimklAuthService.isConfigured,
            onConnect: () => ref.read(authProvider.notifier).connectSimkl(),
            onDisconnect: () => _showDisconnectDialog(
              context, 
              ref, 
              'Simkl', 
              () => ref.read(authProvider.notifier).disconnectSimkl(),
            ),
          ),
          if (authState.isTraktConnected || authState.isSimklConnected) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildSyncProviderSelector(context, ref, authState),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncProviderSelector(BuildContext context, WidgetRef ref, AuthState authState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'Senkronizasyon',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSyncOption(
            context: context,
            ref: ref,
            title: 'Kapalı',
            subtitle: 'Yerel kütüphane',
            provider: SyncProvider.none,
            currentProvider: authState.activeSyncProvider,
            enabled: true,
          ),
          if (authState.isTraktConnected)
            _buildSyncOption(
              context: context,
              ref: ref,
              title: 'Trakt',
              subtitle: '@${authState.traktUser?.username}',
              provider: SyncProvider.trakt,
              currentProvider: authState.activeSyncProvider,
              enabled: true,
              color: const Color(0xFFED1C24),
            ),
          if (authState.isSimklConnected)
            _buildSyncOption(
              context: context,
              ref: ref,
              title: 'Simkl',
              subtitle: '@${authState.simklUser?.username}',
              provider: SyncProvider.simkl,
              currentProvider: authState.activeSyncProvider,
              enabled: true,
              color: const Color(0xFF0099FF),
            ),
          if (authState.hasSyncEnabled) ...[
            const SizedBox(height: 12),
            _buildSyncNowButton(context, ref, authState),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncNowButton(BuildContext context, WidgetRef ref, AuthState authState) {
    return Consumer(
      builder: (context, ref, child) {
        final isSyncing = ref.watch(_syncingProvider);
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSyncing ? null : () => _performSync(context, ref, authState),
            icon: isSyncing 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 18),
            label: Text(isSyncing ? 'Senkronize ediliyor...' : 'Şimdi Senkronize Et'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: BorderSide(color: AppTheme.accent.withAlpha(100)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref, AuthState authState) async {
    final syncService = authState.syncService;
    if (syncService == null) return;

    ref.read(_syncingProvider.notifier).set(true);

    try {
      final libraryNotifier = ref.read(libraryProvider.notifier);
      libraryNotifier.setSyncService(syncService);
      
      await libraryNotifier.processPendingSync();
      
      await libraryNotifier.syncFromRemote();

      if (context.mounted) {
        final libraryState = ref.read(libraryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Senkronizasyon tamamlandı: ${libraryState.items.length} içerik',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senkronizasyon hatası: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      ref.read(_syncingProvider.notifier).set(false);
    }
  }

  Widget _buildSyncOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required SyncProvider provider,
    required SyncProvider currentProvider,
    required bool enabled,
    Color? color,
  }) {
    final isSelected = provider == currentProvider;
    return InkWell(
      onTap: enabled ? () => ref.read(authProvider.notifier).setActiveSyncProvider(provider) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? (color ?? AppTheme.accent) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && provider != SyncProvider.none)
              Icon(Icons.check_circle, color: color ?? AppTheme.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required WidgetRef ref,
    required String serviceName,
    required IconData serviceIcon,
    required Color iconColor,
    required bool isConnected,
    required String? username,
    required bool isLoading,
    required bool isConfigured,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(30),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Icon(serviceIcon, color: iconColor, size: 20),
      ),
      title: Text(
        serviceName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isConnected 
            ? '@$username' 
            : (isConfigured ? 'Bağlı değil' : 'API yapılandırılmamış'),
        style: TextStyle(
          color: isConnected ? AppTheme.statusCompleted : Colors.grey[500],
          fontSize: 12,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isConnected
              ? TextButton(
                  onPressed: onDisconnect,
                  child: const Text(
                    'Bağlantıyı Kes',
                    style: TextStyle(color: AppTheme.statusDropped, fontSize: 12),
                  ),
                )
              : isConfigured
                  ? TextButton(
                      onPressed: onConnect,
                      child: Text(
                        'Bağlan',
                        style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )
                  : Icon(Icons.warning_amber, color: Colors.grey[600], size: 20),
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref, String serviceName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.statusOnHold.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.link_off, color: AppTheme.statusOnHold, size: 20),
            ),
            const SizedBox(width: 12),
            Text('$serviceName Bağlantısını Kes', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          '$serviceName hesabınızın bağlantısını kesmek istediğinize emin misiniz? Senkronizasyon verileri etkilenmeyecek.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$serviceName bağlantısı kesildi'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusOnHold,
            ),
            child: const Text('Bağlantıyı Kes'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDangerCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.statusDropped.withAlpha(10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.statusDropped.withAlpha(50)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(30),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppTheme.statusDropped : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: trailing ?? (onTap != null 
          ? Icon(Icons.chevron_right, color: Colors.grey[600])
          : null),
    );
  }

  String _getRegionName(String region, AppLocalizations l10n) {
    switch (region) {
      case 'TR': return l10n.regionTurkey;
      case 'US': return l10n.regionUSA;
      case 'DE': return l10n.regionGermany;
      case 'FR': return l10n.regionFrance;
      default: return region;
    }
  }

  void _showLanguagePicker(BuildContext context, LocaleNotifier notifier, LocaleState state) {
    final languages = [
      ('tr', 'TR', 'Türkçe', '🇹🇷'),
      ('en', 'US', 'English', '🇺🇸'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Dil Seçin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...languages.map((lang) {
                final isSelected = state.locale.languageCode == lang.$1;
                return ListTile(
                  leading: Text(lang.$4, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    lang.$3,
                    style: TextStyle(
                      color: isSelected ? AppTheme.accent : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: AppTheme.accent)
                      : null,
                  onTap: () {
                    notifier.setLocale(Locale(lang.$1, lang.$2));
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegionPicker(BuildContext context, LocaleNotifier notifier, LocaleState state, AppLocalizations l10n) {
    final regions = [
      ('TR', l10n.regionTurkey, '🇹🇷'),
      ('US', l10n.regionUSA, '🇺🇸'),
      ('DE', l10n.regionGermany, '🇩🇪'),
      ('FR', l10n.regionFrance, '🇫🇷'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.settingsContentRegion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...regions.map((region) {
                final isSelected = state.region == region.$1;
                return ListTile(
                  leading: Text(region.$3, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    region.$2,
                    style: TextStyle(
                      color: isSelected ? AppTheme.accent : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: AppTheme.accent)
                      : null,
                  onTap: () {
                    notifier.setRegion(region.$1);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.statusOnHold.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.cached, color: AppTheme.statusOnHold, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Önbelleği Temizle', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Tüm önbellek verileri silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.cacheCleared),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusOnHold,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showResetLibraryDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.statusDropped.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.delete_sweep, color: AppTheme.statusDropped, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Kütüphaneyi Sıfırla', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Tüm kayıtlı filmler ve diziler silinecek. Bu işlem geri alınamaz!',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(libraryProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kütüphane sıfırlandı'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusDropped,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
