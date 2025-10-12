import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/analysis_service.dart';
import 'services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/routes/app_router.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/match_service.dart';
import 'package:frontend/services/player_service.dart';
import 'package:frontend/services/team_service.dart';
import 'package:frontend/services/reunion_service.dart';
import 'package:frontend/services/training_session_service.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/services/match_lineup_service.dart';
import 'package:frontend/services/formation_service.dart';
import 'package:frontend/services/player_match_statistics_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/theme_notifier.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/l10n/app_localizations.dart'; 
import 'package:frontend/services/locale_notifier.dart';
import 'package:frontend/services/video_analysis_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String baseUrl = '';
  const String localApiUrl = 'http://192.168.1.180:8000/api';
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      baseUrl = dotenv.env['BASE_URL'] ?? localApiUrl;
    } catch (e, stack) {
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup error: $e\n$stack'),
          ),
        ),
      ));
      return;
    }
  } else {
    baseUrl = localApiUrl;
  }

  final apiClient = ApiClient(baseUrl: baseUrl, httpClient: http.Client());
  final authService = AuthService(apiClient: apiClient);
  await authService.init();

  final initialThemeMode = await ThemeNotifier.getThemeModeFromPrefs();
  final initialLocale = await LocaleNotifier.getLocaleFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => apiClient),
        ChangeNotifierProvider<AuthService>(create: (_) => authService),
        ChangeNotifierProvider<AnalysisService>(
          create: (context) => AnalysisService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<TeamService>(
          create: (context) => TeamService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<MatchService>(
          create: (context) => MatchService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
            teamService: Provider.of<TeamService>(context, listen: false),
          ),
        ),
        Provider<PlayerService>(
          create: (context) => PlayerService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<ReunionService>(
          create: (context) => ReunionService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<TrainingSessionService>(
          create: (context) => TrainingSessionService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<EventService>(
          create: (context) => EventService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<MatchLineupService>(
          create: (context) => MatchLineupService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<FormationService>(
          create: (context) => FormationService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        Provider<PlayerMatchStatisticsService>(
          create: (context) => PlayerMatchStatisticsService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<VideoAnalysisService>(
          create: (context) => VideoAnalysisService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier(initialThemeMode)),
        ChangeNotifierProvider<LocaleNotifier>(create: (_) => LocaleNotifier(initialLocale)),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, LocaleNotifier>(
      builder: (context, themeNotifier, localeNotifier, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Soccer Analytics',
          themeMode: themeNotifier.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFF50C878),
            cardColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF50C878),
              secondary: const Color(0xFFE94560),
              background: Colors.white,
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onBackground: Colors.black,
              onSurface: Colors.black,
              error: Colors.redAccent,
              onError: Colors.white,
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.grey[700]),
              titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              headlineSmall: TextStyle(color: Color(0xFFE94560)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF50C878),
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF50C878),
              unselectedItemColor: Colors.grey[700],
              showUnselectedLabels: true,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1A1A2E),
            primaryColor: const Color(0xFF50C878),
            cardColor: const Color(0xFF16213E),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF50C878),
              secondary: const Color(0xFFE94560),
              background: const Color(0xFF1A1A2E),
              surface: const Color(0xFF16213E),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onBackground: Colors.white,
              onSurface: Colors.white,
              error: Colors.redAccent,
              onError: Colors.white,
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Color(0xFFA9A9A9)),
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              headlineSmall: TextStyle(color: Color(0xFFE94560)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF16213E),
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF16213E),
              selectedItemColor: Color(0xFF50C878),
              unselectedItemColor: Color(0xFFA9A9A9),
              showUnselectedLabels: true,
            ),
            useMaterial3: true,
          ),
          locale: localeNotifier.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', 'TN'), // Arabic (Tunisia)
            Locale('fr', ''), // French
          ],
          routerConfig: buildAppRouter(context),
        );
      },
    );
  }
}