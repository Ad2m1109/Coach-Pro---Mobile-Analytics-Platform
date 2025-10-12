import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/analyze/analyze_screen.dart';
import 'package:frontend/features/matches/matches_screen.dart';
import 'package:frontend/features/players/players_screen.dart';
import 'package:frontend/features/settings/settings_screen.dart';
import 'package:frontend/features/strategie/strategie_screen.dart';
import 'package:frontend/features/match_details/match_details_screen.dart';
import 'package:frontend/features/match_statistics/match_statistics_screen.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/widgets/scaffold_with_nav_bar.dart'; // Import the new widget
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';

// Define route names
class AppRouteConstants {
  static const String strategieRouteName = 'strategie';
  static const String matchesRouteName = 'matches';
  static const String playersRouteName = 'players';
  static const String analyzeRouteName = 'analyze';
  static const String settingsRouteName = 'settings';
  static const String loginRouteName = 'login';
  static const String registerRouteName = 'register';
}

GoRouter buildAppRouter(BuildContext context) {
  final authService = Provider.of<AuthService>(context, listen: false);

  return GoRouter(
    initialLocation: '/' + AppRouteConstants.strategieRouteName,
    refreshListenable: authService,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authService.isAuthenticated;

      // Check if the current location is one of the authentication routes
      final isAuthenticating = state.uri.toString() == '/' + AppRouteConstants.loginRouteName ||
                               state.uri.toString() == '/' + AppRouteConstants.registerRouteName;

      // If not authenticated and not on an auth page, redirect to login
      if (!isAuthenticated && !isAuthenticating) {
        return '/' + AppRouteConstants.loginRouteName;
      }
      // If authenticated and on an auth page, redirect to home
      if (isAuthenticated && isAuthenticating) {
        return '/' + AppRouteConstants.strategieRouteName;
      }

      // No redirect needed
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/' + AppRouteConstants.loginRouteName,
        name: AppRouteConstants.loginRouteName,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/' + AppRouteConstants.registerRouteName,
        name: AppRouteConstants.registerRouteName,
        builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          print('ShellRoute builder called');
          return ScaffoldWithNavBar(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/' + AppRouteConstants.strategieRouteName,
            name: AppRouteConstants.strategieRouteName,
            builder: (BuildContext context, GoRouterState state) {
              print('StrategieScreen route builder called');
              return const StrategieScreen();
            },
          ),
          GoRoute(
            path: '/' + AppRouteConstants.matchesRouteName,
            name: AppRouteConstants.matchesRouteName,
            builder: (BuildContext context, GoRouterState state) {
              print('MatchesScreen route builder called');
              return const MatchesScreen();
            },
            routes: [
              GoRoute(
                path: 'details',
                name: 'match-details',
                builder: (BuildContext context, GoRouterState state) {
                  final match = state.extra;
                  if (match is! Match) {
                    // Handle the case where 'extra' is not a Match object or is null
                    // For now, we'll throw an error, but in a real app, you might
                    // navigate to an error screen or the matches list.
                    throw Exception('Invalid match object passed to match-details route.');
                  }
                  return MatchDetailsScreen(match: match);
                },
              ),
              GoRoute(
                path: 'statistics',
                name: 'match-statistics',
                builder: (BuildContext context, GoRouterState state) {
                  final match = state.extra;
                  if (match is! Match) {
                    throw Exception('Invalid match object passed to match-statistics route.');
                  }
                  return MatchStatisticsScreen(match: match);
                },
              ),
            ]
          ),
          GoRoute(
            path: '/' + AppRouteConstants.playersRouteName,
            name: AppRouteConstants.playersRouteName,
            builder: (BuildContext context, GoRouterState state) {
              print('PlayersScreen route builder called');
              return const PlayersScreen();
            },
          ),
          GoRoute(
            path: '/' + AppRouteConstants.analyzeRouteName,
            name: AppRouteConstants.analyzeRouteName,
            builder: (BuildContext context, GoRouterState state) {
              print('AnalyzeScreen route builder called');
              return const AnalyzeScreen();
            },
          ),
          GoRoute(
            path: '/' + AppRouteConstants.settingsRouteName,
            name: AppRouteConstants.settingsRouteName,
            builder: (BuildContext context, GoRouterState state) {
              print('SettingsScreen route builder called');
              return const SettingsScreen();
            },
          ),
        ],
      ),
    ],
  );
}