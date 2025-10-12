import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Soccer Analytics'**
  String get appTitle;

  /// No description provided for @generalPreferences.
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get generalPreferences;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @enableDataSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Data Sync'**
  String get enableDataSync;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @tunisianArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية (تونس)'**
  String get tunisianArabic;

  /// No description provided for @strategie.
  ///
  /// In en, this message translates to:
  /// **'Strategie'**
  String get strategie;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as:'**
  String get loggedInAs;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @reunions.
  ///
  /// In en, this message translates to:
  /// **'Reunions'**
  String get reunions;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @allMatches.
  ///
  /// In en, this message translates to:
  /// **'All Matches'**
  String get allMatches;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @filterByEvent.
  ///
  /// In en, this message translates to:
  /// **'Filter by Event'**
  String get filterByEvent;

  /// No description provided for @errorLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events:'**
  String get errorLoadingEvents;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found.'**
  String get noMatchesFound;

  /// No description provided for @noMatchesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No matches in this category.'**
  String get noMatchesInCategory;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event:'**
  String get event;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get searchSettings;

  /// No description provided for @teamAndAccount.
  ///
  /// In en, this message translates to:
  /// **'Team & Account'**
  String get teamAndAccount;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @manageEvents.
  ///
  /// In en, this message translates to:
  /// **'Manage Events'**
  String get manageEvents;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addReunion.
  ///
  /// In en, this message translates to:
  /// **'Add Reunion'**
  String get addReunion;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @pleaseEnterATitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterATitle;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @pleaseEnterALocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get pleaseEnterALocation;

  /// No description provided for @iconNameExample.
  ///
  /// In en, this message translates to:
  /// **'Icon Name (e.g., group_work)'**
  String get iconNameExample;

  /// No description provided for @pleaseEnterAnIconName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an icon name'**
  String get pleaseEnterAnIconName;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @saveReunion.
  ///
  /// In en, this message translates to:
  /// **'Save Reunion'**
  String get saveReunion;

  /// No description provided for @reunionCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reunion created successfully!'**
  String get reunionCreatedSuccessfully;

  /// No description provided for @addTrainingSession.
  ///
  /// In en, this message translates to:
  /// **'Add Training Session'**
  String get addTrainingSession;

  /// No description provided for @focusExample.
  ///
  /// In en, this message translates to:
  /// **'Focus (e.g., Defense)'**
  String get focusExample;

  /// No description provided for @pleaseEnterAFocus.
  ///
  /// In en, this message translates to:
  /// **'Please enter a focus'**
  String get pleaseEnterAFocus;

  /// No description provided for @iconNameExampleTraining.
  ///
  /// In en, this message translates to:
  /// **'Icon Name (e.g., sports_soccer)'**
  String get iconNameExampleTraining;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// No description provided for @trainingSessionCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Training session created successfully!'**
  String get trainingSessionCreatedSuccessfully;

  /// No description provided for @noReunionsFound.
  ///
  /// In en, this message translates to:
  /// **'No reunions found.'**
  String get noReunionsFound;

  /// No description provided for @noTrainingSessionsFound.
  ///
  /// In en, this message translates to:
  /// **'No training sessions found.'**
  String get noTrainingSessionsFound;

  /// No description provided for @newAnalysis.
  ///
  /// In en, this message translates to:
  /// **'New Analysis'**
  String get newAnalysis;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noAnalysisHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No analysis history found.'**
  String get noAnalysisHistoryFound;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected.'**
  String get noImageSelected;

  /// No description provided for @pleaseSelectAnImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first.'**
  String get pleaseSelectAnImageFirst;

  /// No description provided for @uploadingAndAnalyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading and analyzing image...'**
  String get uploadingAndAnalyzingImage;

  /// No description provided for @detectionCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Detection completed successfully!'**
  String get detectionCompletedSuccessfully;

  /// No description provided for @imageAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Image Analysis'**
  String get imageAnalysis;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @runDetection.
  ///
  /// In en, this message translates to:
  /// **'Run Detection'**
  String get runDetection;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @anUnexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get anUnexpectedErrorOccurred;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @dontHaveAnAccountRegisterHere.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register here.'**
  String get dontHaveAnAccountRegisterHere;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You are now logged in.'**
  String get registrationSuccessful;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordTooShort;

  /// No description provided for @fullNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Full Name (Optional)'**
  String get fullNameOptional;

  /// No description provided for @alreadyHaveAnAccountLoginHere.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login here.'**
  String get alreadyHaveAnAccountLoginHere;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get vs;

  /// No description provided for @saveFormation.
  ///
  /// In en, this message translates to:
  /// **'Save Formation'**
  String get saveFormation;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found.'**
  String get noDataFound;

  /// No description provided for @selectFormation.
  ///
  /// In en, this message translates to:
  /// **'Select Formation'**
  String get selectFormation;

  /// No description provided for @pleaseSelectAValidFormation.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid formation.'**
  String get pleaseSelectAValidFormation;

  /// No description provided for @pleaseAssign11Players.
  ///
  /// In en, this message translates to:
  /// **'Please assign a player to all 11 positions.'**
  String get pleaseAssign11Players;

  /// No description provided for @formationSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Formation saved successfully!'**
  String get formationSavedSuccessfully;

  /// No description provided for @matchReport.
  ///
  /// In en, this message translates to:
  /// **'Match Report'**
  String get matchReport;

  /// No description provided for @eventTimeline.
  ///
  /// In en, this message translates to:
  /// **'Event Timeline'**
  String get eventTimeline;

  /// No description provided for @lineups.
  ///
  /// In en, this message translates to:
  /// **'Lineups'**
  String get lineups;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @noDetailsFoundForThisMatch.
  ///
  /// In en, this message translates to:
  /// **'No details found for this match.'**
  String get noDetailsFoundForThisMatch;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @venue.
  ///
  /// In en, this message translates to:
  /// **'Venue:'**
  String get venue;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @minutesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Minutes Played:'**
  String get minutesPlayed;

  /// No description provided for @shots.
  ///
  /// In en, this message translates to:
  /// **'Shots:'**
  String get shots;

  /// No description provided for @shotsOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Shots on Target:'**
  String get shotsOnTarget;

  /// No description provided for @passes.
  ///
  /// In en, this message translates to:
  /// **'Passes:'**
  String get passes;

  /// No description provided for @accuratePasses.
  ///
  /// In en, this message translates to:
  /// **'Accurate Passes:'**
  String get accuratePasses;

  /// No description provided for @tackles.
  ///
  /// In en, this message translates to:
  /// **'Tackles:'**
  String get tackles;

  /// No description provided for @keyPasses.
  ///
  /// In en, this message translates to:
  /// **'Key Passes:'**
  String get keyPasses;

  /// No description provided for @expectedGoalsXG.
  ///
  /// In en, this message translates to:
  /// **'Expected Goals (xG):'**
  String get expectedGoalsXG;

  /// No description provided for @progressiveCarries.
  ///
  /// In en, this message translates to:
  /// **'Progressive Carries:'**
  String get progressiveCarries;

  /// No description provided for @defensiveCoverage.
  ///
  /// In en, this message translates to:
  /// **'Defensive Coverage:'**
  String get defensiveCoverage;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating:'**
  String get rating;

  /// No description provided for @outOf10.
  ///
  /// In en, this message translates to:
  /// **'/10'**
  String get outOf10;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notes;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available.'**
  String get noNotesAvailable;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @averageNA.
  ///
  /// In en, this message translates to:
  /// **'Average: N/A'**
  String get averageNA;

  /// No description provided for @teamComparison.
  ///
  /// In en, this message translates to:
  /// **'Team Comparison'**
  String get teamComparison;

  /// No description provided for @possession.
  ///
  /// In en, this message translates to:
  /// **'Possession'**
  String get possession;

  /// No description provided for @totalShots.
  ///
  /// In en, this message translates to:
  /// **'Total Shots'**
  String get totalShots;

  /// No description provided for @final3rdPasses.
  ///
  /// In en, this message translates to:
  /// **'Final 3rd Passes'**
  String get final3rdPasses;

  /// No description provided for @playerPerformance.
  ///
  /// In en, this message translates to:
  /// **'Player Performance'**
  String get playerPerformance;

  /// No description provided for @addNewEvent.
  ///
  /// In en, this message translates to:
  /// **'Add New Event'**
  String get addNewEvent;

  /// No description provided for @eventName.
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get eventName;

  /// No description provided for @pleaseEnterAnEventName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an event name'**
  String get pleaseEnterAnEventName;

  /// No description provided for @saveEvent.
  ///
  /// In en, this message translates to:
  /// **'Save Event'**
  String get saveEvent;

  /// No description provided for @eventCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully!'**
  String get eventCreatedSuccessfully;

  /// No description provided for @addNewMatch.
  ///
  /// In en, this message translates to:
  /// **'Add New Match'**
  String get addNewMatch;

  /// No description provided for @opponentTeamName.
  ///
  /// In en, this message translates to:
  /// **'Opponent Team Name'**
  String get opponentTeamName;

  /// No description provided for @pleaseEnterOpponentTeamName.
  ///
  /// In en, this message translates to:
  /// **'Please enter opponent team name'**
  String get pleaseEnterOpponentTeamName;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get time;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @homeGame.
  ///
  /// In en, this message translates to:
  /// **'Home Game'**
  String get homeGame;

  /// No description provided for @noEventsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No events available.'**
  String get noEventsAvailable;

  /// No description provided for @pleaseSelectAnEvent.
  ///
  /// In en, this message translates to:
  /// **'Please select an event'**
  String get pleaseSelectAnEvent;

  /// No description provided for @saveMatch.
  ///
  /// In en, this message translates to:
  /// **'Save Match'**
  String get saveMatch;

  /// No description provided for @matchCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Match created successfully!'**
  String get matchCreatedSuccessfully;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @jerseyNumber.
  ///
  /// In en, this message translates to:
  /// **'Jersey Number'**
  String get jerseyNumber;

  /// No description provided for @marketValue.
  ///
  /// In en, this message translates to:
  /// **'Market Value'**
  String get marketValue;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found.'**
  String get noPlayersFound;

  /// No description provided for @addNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Player'**
  String get addNewPlayer;

  /// No description provided for @playerName.
  ///
  /// In en, this message translates to:
  /// **'Player Name'**
  String get playerName;

  /// No description provided for @pleaseEnterPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a player name'**
  String get pleaseEnterPlayerName;

  /// No description provided for @birthDateSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date: Select Date'**
  String get birthDateSelectDate;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date:'**
  String get birthDate;

  /// No description provided for @dominantFoot.
  ///
  /// In en, this message translates to:
  /// **'Dominant Foot'**
  String get dominantFoot;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get right;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @savePlayer.
  ///
  /// In en, this message translates to:
  /// **'Save Player'**
  String get savePlayer;

  /// No description provided for @noTeamFoundForUser.
  ///
  /// In en, this message translates to:
  /// **'No team found for the current user. Please create a team first.'**
  String get noTeamFoundForUser;

  /// No description provided for @playerCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Player created successfully!'**
  String get playerCreatedSuccessfully;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @imageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image updated successfully!'**
  String get imageUpdatedSuccessfully;

  /// No description provided for @noMatchStatsFoundForPlayer.
  ///
  /// In en, this message translates to:
  /// **'No match statistics found for this player.'**
  String get noMatchStatsFoundForPlayer;

  /// No description provided for @ratingEvolution.
  ///
  /// In en, this message translates to:
  /// **'Rating Evolution'**
  String get ratingEvolution;

  /// No description provided for @matchHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get matchHistory;

  /// No description provided for @matchId.
  ///
  /// In en, this message translates to:
  /// **'Match ID:'**
  String get matchId;

  /// No description provided for @onTarget.
  ///
  /// In en, this message translates to:
  /// **'on target'**
  String get onTarget;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Your ultimate companion for analyzing soccer matches, tracking player performance, and strategizing for success.'**
  String get appDescription;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Soccer Analytics. All rights reserved.'**
  String get copyright;

  /// No description provided for @noTeamFoundCreateOne.
  ///
  /// In en, this message translates to:
  /// **'No team found. Please create a team.'**
  String get noTeamFoundCreateOne;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// No description provided for @pleaseEnterTeamName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a team name'**
  String get pleaseEnterTeamName;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get secondaryColor;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @selectAColor.
  ///
  /// In en, this message translates to:
  /// **'Select a Color'**
  String get selectAColor;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @changesSavedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Changes saved automatically.'**
  String get changesSavedAutomatically;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @noDataFoundEnsureLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No data found. Please ensure you are logged in.'**
  String get noDataFoundEnsureLoggedIn;

  /// No description provided for @createTeamToAddLogo.
  ///
  /// In en, this message translates to:
  /// **'Create a team first to add a logo.'**
  String get createTeamToAddLogo;

  /// No description provided for @noTeamFound.
  ///
  /// In en, this message translates to:
  /// **'No team found'**
  String get noTeamFound;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @changePasswordNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Change password functionality is not yet implemented.'**
  String get changePasswordNotImplemented;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @eventDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully!'**
  String get eventDeletedSuccessfully;

  /// No description provided for @teamSettings.
  ///
  /// In en, this message translates to:
  /// **'Team Settings'**
  String get teamSettings;

  /// No description provided for @selectTeam.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectTeam;

  /// No description provided for @primaryColorHex.
  ///
  /// In en, this message translates to:
  /// **'Primary Color (Hex e.g., #FF0000)'**
  String get primaryColorHex;

  /// No description provided for @pleaseEnterPrimaryColor.
  ///
  /// In en, this message translates to:
  /// **'Please enter a primary color'**
  String get pleaseEnterPrimaryColor;

  /// No description provided for @enterValidHexColor.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid hex color (e.g., #FF0000)'**
  String get enterValidHexColor;

  /// No description provided for @secondaryColorHex.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color (Hex e.g., #0000FF)'**
  String get secondaryColorHex;

  /// No description provided for @logoUrl.
  ///
  /// In en, this message translates to:
  /// **'Logo URL'**
  String get logoUrl;

  /// No description provided for @enterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get enterValidUrl;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @teamCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Team created successfully!'**
  String get teamCreatedSuccessfully;

  /// No description provided for @teamUpdateNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Team update not yet implemented in API.'**
  String get teamUpdateNotImplemented;

  /// No description provided for @failedToSaveFormation.
  ///
  /// In en, this message translates to:
  /// **'Failed to save formation: {error}'**
  String failedToSaveFormation(String error);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {message}'**
  String registrationFailed(String message);

  /// No description provided for @anUnexpectedErrorOccurredWithMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String anUnexpectedErrorOccurredWithMessage(String error);

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected: {name}'**
  String imageSelected(String name);

  /// No description provided for @detectionCompleteResponse.
  ///
  /// In en, this message translates to:
  /// **'Detection complete! Response: {responseBody}'**
  String detectionCompleteResponse(String responseBody);

  /// No description provided for @detectionFailedWithCode.
  ///
  /// In en, this message translates to:
  /// **'Detection failed: {statusCode} - {errorBody}'**
  String detectionFailedWithCode(int statusCode, String errorBody);

  /// No description provided for @detectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Detection failed: {statusCode}'**
  String detectionFailed(int statusCode);

  /// No description provided for @errorDuringDetection.
  ///
  /// In en, this message translates to:
  /// **'Error during detection: {error}'**
  String errorDuringDetection(String error);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String selected(String name);

  /// No description provided for @failedToCreateMatch.
  ///
  /// In en, this message translates to:
  /// **'Failed to create match: {error}'**
  String failedToCreateMatch(String error);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String date(String date);

  /// No description provided for @failedToCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to create event: {error}'**
  String failedToCreateEvent(String error);

  /// No description provided for @failedToGetUserTeam.
  ///
  /// In en, this message translates to:
  /// **'Failed to get user team: {error}'**
  String failedToGetUserTeam(String error);

  /// No description provided for @failedToCreatePlayer.
  ///
  /// In en, this message translates to:
  /// **'Failed to create player: {error}'**
  String failedToCreatePlayer(String error);

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String failedToUploadImage(String error);

  /// No description provided for @logoUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logo updated successfully!'**
  String get logoUpdatedSuccessfully;

  /// No description provided for @failedToUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload logo: {error}'**
  String failedToUploadLogo(String error);

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes: {error}'**
  String failedToSaveChanges(String error);

  /// No description provided for @confirmDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the event \"{eventName}\"'**
  String confirmDeleteEvent(String eventName);

  /// No description provided for @failedToDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete event: {error}'**
  String failedToDeleteEvent(String error);

  /// No description provided for @failedToCreateReunion.
  ///
  /// In en, this message translates to:
  /// **'Failed to create reunion: {error}'**
  String failedToCreateReunion(String error);

  /// No description provided for @failedToCreateSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to create session: {error}'**
  String failedToCreateSession(String error);

  /// No description provided for @pressures.
  ///
  /// In en, this message translates to:
  /// **'Pressures'**
  String get pressures;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No events found.'**
  String get noEventsFound;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideo;

  /// No description provided for @selectVideoFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a video first'**
  String get selectVideoFirst;

  /// No description provided for @noVideoSelected.
  ///
  /// In en, this message translates to:
  /// **'No video selected'**
  String get noVideoSelected;

  /// No description provided for @uploadingAndAnalyzingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading and analyzing video...'**
  String get uploadingAndAnalyzingVideo;

  /// No description provided for @videoAnalysisProgress.
  ///
  /// In en, this message translates to:
  /// **'Video Analysis Progress'**
  String get videoAnalysisProgress;

  /// No description provided for @videoAnalysisCompleted.
  ///
  /// In en, this message translates to:
  /// **'Video analysis completed!'**
  String get videoAnalysisCompleted;

  /// No description provided for @videoAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Video analysis failed: {error}'**
  String videoAnalysisFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
