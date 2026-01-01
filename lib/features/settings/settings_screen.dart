import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(localeState.locale.languageCode == 'tr' ? 'Türkçe' : 'English'),
            trailing: DropdownButton<String>(
              value: localeState.locale.languageCode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  localeNotifier.setLocale(Locale(newValue, newValue == 'tr' ? 'TR' : 'US'));
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.settingsContentRegion),
            subtitle: Text(localeState.region),
            trailing: DropdownButton<String>(
              value: localeState.region,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  localeNotifier.setRegion(newValue);
                }
              },
              items: [
                DropdownMenuItem(value: 'TR', child: Text(l10n.regionTurkey)),
                DropdownMenuItem(value: 'US', child: Text(l10n.regionUSA)),
                DropdownMenuItem(value: 'DE', child: Text(l10n.regionGermany)),
                DropdownMenuItem(value: 'FR', child: Text(l10n.regionFrance)),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(l10n.clearCache, style: const TextStyle(color: Colors.red)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cacheCleared)),
              );
            },
          ),
        ],
      ),
    );
  }
}
