import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final showAnalyze = authService.appRole != 'player';
    final navRoutes = <String>[
      AppRouteConstants.strategieRouteName,
      AppRouteConstants.matchesRouteName,
      AppRouteConstants.playersRouteName,
      if (showAnalyze) AppRouteConstants.analyzeRouteName,
      AppRouteConstants.settingsRouteName,
    ];

    final navItems = <BottomNavigationBarItem>[
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
      if (showAnalyze)
        BottomNavigationBarItem(
          icon: const Icon(Icons.analytics),
          label: appLocalizations.analyze,
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings),
        label: appLocalizations.settings,
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: navItems,
        currentIndex: _calculateSelectedIndex(context, navRoutes),
        onTap: (int idx) => _onItemTapped(context, idx, navRoutes),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context, List<String> navRoutes) {
    final String location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < navRoutes.length; i++) {
      if (location.startsWith('/${navRoutes[i]}')) return i;
    }
    return navRoutes.length - 1;
  }

  void _onItemTapped(BuildContext context, int index, List<String> navRoutes) {
    if (index >= 0 && index < navRoutes.length) {
      context.goNamed(navRoutes[index]);
    }
  }
}
