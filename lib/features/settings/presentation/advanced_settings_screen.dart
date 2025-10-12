import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/models/user.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.advancedSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.white70),
                  title: Text(appLocalizations.email, style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(user?.email ?? appLocalizations.notLoggedIn, style: Theme.of(context).textTheme.bodyMedium),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.white70),
                  title: Text(appLocalizations.changePassword, style: Theme.of(context).textTheme.bodyLarge),
                  trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.changePasswordNotImplemented)),
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
