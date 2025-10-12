import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/theme_notifier.dart';
import 'package:frontend/l10n/app_localizations.dart'; // New import
import 'package:frontend/services/locale_notifier.dart'; // New import

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notificationsEnabled = true;
  bool _dataSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    // Initialize _selectedLanguage based on current locale
    final localeNotifier = Provider.of<LocaleNotifier>(context, listen: false);
    _setSelectedLanguageFromLocale(localeNotifier.locale);
  }

  void _setSelectedLanguageFromLocale(Locale? locale) {
    if (locale == null) return;
    if (locale.languageCode == 'en') {
      _selectedLanguage = 'English';
    } else if (locale.languageCode == 'ar' && locale.countryCode == 'TN') {
      _selectedLanguage = 'العربية (تونس)';
    } else if (locale.languageCode == 'fr') {
      _selectedLanguage = 'Français';
    } else {
      _selectedLanguage = 'English'; // Fallback
    }
  }

  String _selectedLanguage = 'English'; // Default language

  void _changeLanguage(String? newLanguageDisplayName) {
    if (newLanguageDisplayName == null) return;

    Locale newLocale;
    if (newLanguageDisplayName == 'English') {
      newLocale = const Locale('en', '');
    } else if (newLanguageDisplayName == 'العربية (تونس)') {
      newLocale = const Locale('ar', 'TN');
    } else if (newLanguageDisplayName == 'Français') {
      newLocale = const Locale('fr', '');
    } else {
      return; // Should not happen
    }

    final localeNotifier = Provider.of<LocaleNotifier>(context, listen: false);
    localeNotifier.setLocale(newLocale);

    setState(() {
      _selectedLanguage = newLanguageDisplayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations!.language), // Use localized string
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            appLocalizations!.generalPreferences, // Use localized string
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(appLocalizations!.enableNotifications, style: Theme.of(context).textTheme.bodyLarge), // Use localized string
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile(
                  title: Text(appLocalizations!.darkMode, style: Theme.of(context).textTheme.bodyLarge), // Use localized string
                  value: themeNotifier.themeMode == ThemeMode.dark, // Use themeNotifier's state
                  onChanged: (bool value) {
                    themeNotifier.toggleTheme(value); // Toggle theme via notifier
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile(
                  title: Text(appLocalizations!.enableDataSync, style: Theme.of(context).textTheme.bodyLarge), // Use localized string
                  value: _dataSyncEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _dataSyncEnabled = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  title: Text(appLocalizations!.language, style: Theme.of(context).textTheme.bodyLarge), // Use localized string
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: _changeLanguage,
                      items: <String>['English', 'العربية (تونس)', 'Français']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            appLocalizations!.dataManagement, // Use localized string
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.secondary),
                  title: Text(appLocalizations!.clearCache, style: Theme.of(context).textTheme.bodyLarge), // Use localized string
                  trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations!.clearCache)), // Use localized string
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.cloud_download, color: Theme.of(context).colorScheme.secondary),
                  title: Text(appLocalizations!.exportData, style: Theme.of(context).textTheme.bodyLarge), // Use localized string
                  trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations!.exportData)), // Use localized string
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}