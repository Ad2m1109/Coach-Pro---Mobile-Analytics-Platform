import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:frontend/l10n/app_localizations.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    print('ScaffoldWithNavBar built');
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.military_tech),
            label: appLocalizations.strategie,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_soccer),
            label: appLocalizations.matches,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: appLocalizations.players,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: appLocalizations.analyze,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: appLocalizations.settings,
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(context, idx),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/' + AppRouteConstants.strategieRouteName)) {
      return 0;
    }
    if (location.startsWith('/' + AppRouteConstants.matchesRouteName)) {
      return 1;
    }
    if (location.startsWith('/' + AppRouteConstants.playersRouteName)) {
      return 2;
    }
    if (location.startsWith('/' + AppRouteConstants.analyzeRouteName)) {
      return 3;
    }
    if (location.startsWith('/' + AppRouteConstants.settingsRouteName)) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(AppRouteConstants.strategieRouteName);
        break;
      case 1:
        context.goNamed(AppRouteConstants.matchesRouteName);
        break;
      case 2:
        context.goNamed(AppRouteConstants.playersRouteName);
        break;
      case 3:
        context.goNamed(AppRouteConstants.analyzeRouteName);
        break;
      case 4:
        context.goNamed(AppRouteConstants.settingsRouteName);
        break;
    }
  }
}
