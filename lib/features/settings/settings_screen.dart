import 'package:flutter/material.dart';
import 'package:frontend/features/settings/presentation/about_screen.dart';
import 'package:frontend/features/settings/presentation/account_and_team_screen.dart';
import 'package:frontend/features/settings/presentation/advanced_settings_screen.dart';
import 'package:frontend/features/settings/presentation/events_settings_screen.dart';
import 'package:frontend/features/settings/presentation/preferences_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmLogout),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(appLocalizations.areYouSureYouWantToLogout),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(appLocalizations.logout),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Provider.of<AuthService>(context, listen: false).logout();
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.settings),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: appLocalizations.searchSettings,
                floatingLabelStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              ),
              style: const TextStyle(fontSize: 14.0, color: Colors.black),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: _buildSettingsOptions(context),
      ),
    );
  }

  List<Widget> _buildSettingsOptions(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> allOptions = [
      {
        'title': appLocalizations.teamAndAccount,
        'icon': Icons.account_circle,
        'screen': const AccountAndTeamScreen(),
      },
      {
        'title': appLocalizations.preferences,
        'icon': Icons.settings_applications,
        'screen': const PreferencesScreen(),
      },
      {
        'title': appLocalizations.manageEvents,
        'icon': Icons.event,
        'screen': const EventsSettingsScreen(),
      },
      {
        'title': appLocalizations.advancedSettings,
        'icon': Icons.security,
        'screen': const AdvancedSettingsScreen(),
      },
      {
        'title': appLocalizations.about,
        'icon': Icons.info,
        'screen': const AboutScreen(),
      },
    ];

    final filteredOptions = allOptions.where((option) {
      return option['title'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return [
      ...filteredOptions.map((option) {
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            leading: Icon(option['icon'], color: Theme.of(context).colorScheme.primary),
            title: Text(option['title'], style: Theme.of(context).textTheme.titleLarge),
            trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => option['screen']),
              );
            },
          ),
        );
      }).toList(),
      // Logout option is always visible, not filtered by search
      Card(
        color: Theme.of(context).cardColor,
        margin: const EdgeInsets.only(top: 16.0),
        child: ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.secondary),
          title: Text(appLocalizations.logout, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          onTap: () => _showLogoutConfirmationDialog(context),
        ),
      ),
    ];
  }
}
