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
import 'package:frontend/services/note_service.dart';
import 'package:frontend/core/design_system/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String baseUrl = '';
  String analysisBaseUrl = '';
  
  try {
    await dotenv.load(fileName: ".env");
    
    // Use BASE_URL for mobile/production, localApiUrl for web/development
    if (kIsWeb) {
      baseUrl = dotenv.env['localApiUrl'] ?? dotenv.env['BASE_URL'] ?? '';
      analysisBaseUrl = dotenv.env['localAnalysisApiUrl'] ?? dotenv.env['ANALYSIS_BASE_URL'] ?? '';
    } else {
      baseUrl = dotenv.env['BASE_URL'] ?? '';
      analysisBaseUrl = dotenv.env['ANALYSIS_BASE_URL'] ?? '';
    }
    
    // Optional: Add debug logging
    if (kDebugMode) {
      print('Running on ${kIsWeb ? 'Web' : 'Mobile'}');
      print('Base URL: $baseUrl');
      print('Analysis Base URL: $analysisBaseUrl');
    }
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

  final apiClient = ApiClient(baseUrl: baseUrl, httpClient: http.Client());
  final analysisApiClient = ApiClient(baseUrl: analysisBaseUrl, httpClient: http.Client());
  final authService = AuthService(apiClient: apiClient, analysisApiClient: analysisApiClient);
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
            apiClient: analysisApiClient, // Use the dedicated analysis API client
          ),
        ),
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier(initialThemeMode)),
        Provider<NoteService>(
          create: (context) => NoteService(
            apiClient: Provider.of<ApiClient>(context, listen: false),
          ),
        ),
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
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: localeNotifier.locale,
          localizationsDelegates: const [
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