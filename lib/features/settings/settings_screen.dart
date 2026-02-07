import 'package:flutter/material.dart';
import 'package:frontend/features/settings/presentation/about_screen.dart';
import 'package:frontend/features/settings/presentation/account_and_team_screen.dart';
import 'package:frontend/features/settings/presentation/advanced_settings_screen.dart';
import 'package:frontend/features/settings/presentation/events_settings_screen.dart';
import 'package:frontend/features/settings/presentation/preferences_screen.dart';
import 'package:frontend/features/staff/staff_list_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';

import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmLogout),
          content: Text(appLocalizations.areYouSureYouWantToLogout),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: appLocalizations.searchSettings,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.m),
              ),
              style: const TextStyle(fontSize: 14.0),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: _buildSettingsOptions(context),
      ),
    );
  }

  List<Widget> _buildSettingsOptions(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> allOptions = [
      {
        'title': appLocalizations.teamAndAccount,
        'icon': Icons.account_circle_outlined,
        'screen': const AccountAndTeamScreen(),
      },
      {
        'title': appLocalizations.preferences,
        'icon': Icons.settings_outlined,
        'screen': const PreferencesScreen(),
      },
      {
        'title': appLocalizations.manageEvents,
        'icon': Icons.event_outlined,
        'screen': const EventsSettingsScreen(),
      },
      {
        'title': 'Manage Staff',
        'icon': Icons.people_outline,
        'screen': const StaffListScreen(),
      },
      {
        'title': appLocalizations.advancedSettings,
        'icon': Icons.security_outlined,
        'screen': const AdvancedSettingsScreen(),
      },
      {
        'title': appLocalizations.about,
        'icon': Icons.info_outline,
        'screen': const AboutScreen(),
      },
    ];

    final filteredOptions = allOptions.where((option) {
      return option['title'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return [
      ...filteredOptions.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: CustomCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => option['screen']),
              );
            },
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(option['icon'], color: Theme.of(context).colorScheme.primary),
              title: Text(option['title'], style: Theme.of(context).textTheme.titleMedium),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
          ),
        );
      }).toList(),
      const SizedBox(height: AppSpacing.m),
      CustomCard(
        onTap: () => _showLogoutConfirmationDialog(context),
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text(
            appLocalizations.logout,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    ];
  }
}
