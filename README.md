# Coach Pro - Mobile Analytics Platform

A comprehensive data-driven mobile application designed for football coaches to manage teams, analyze match performance, and make informed tactical decisions through advanced video analytics and performance metrics visualization.

## Product Vision

**Coach Pro** transforms raw match footage into actionable insights. By combining intuitive team management tools with cutting-edge AI-powered video analysis, coaches can track player performance, visualize movement patterns, and optimize tactical strategies—all from a mobile device.

## Key Features

### 🎥 Video Analysis Pipeline
- **Smart Upload Tracking**: Real-time progress bar shows exactly how much of your video has been sent to the server.
- **Detached Analysis**: Start an analysis and go back to the home screen—the process stays alive and you can return to watch the progress anytime.
- **Immediate History Presence**: Matches appear in your history as soon as the upload finishes, tracking their live analysis status.
- **AI Tracking**: Integrated player detection and metric calculation (distance, speed) via dedicated gRPC engine.

### 📊 Performance Metrics Dashboard
- **Speed Analysis**: View player top speeds, average velocities, and sprint statistics in meters per second
- **Distance Tracking**: Total distance covered, distance per segment, and intensity zones
- **Heatmaps**: Visual representation of player positioning and movement patterns across the pitch
- **Comparative Analytics**: Side-by-side player comparisons and team-level aggregations

### 👥 Team Management
- **Player Profiles**: Comprehensive player information including positions, jersey numbers, and historical stats
- **Roster Management**: Add, edit, and organize your squad with intuitive interfaces
- **Team Organization**: Create and manage multiple teams with separate rosters

### 📅 Match Scheduling & History
- **Upcoming Matches**: Schedule future matches with opponent details, venue, and kickoff times
- **Match Results**: Review past match outcomes with detailed statistics and video replays
- **Season Overview**: Track team performance trends across multiple matches

### 🎯 Tactical Planning
- **Formation Editor**: Visually design and save team formations (4-4-2, 4-3-3, 3-5-2, etc.)
- **Lineup Builder**: Assign players to positions and manage substitutions
- **Training Sessions**: Plan and log training activities with session notes

### 🌍 Multilingual Support
Full localization for:
- **English** (en)
- **Français** (fr)
- **العربية** (ar)

Interface automatically adapts to device language settings with RTL support for Arabic.

### 🎨 Modern UI/UX
- **Clean Design**: Material Design 3 principles with custom theme support
- **Responsive Layouts**: Optimized for phones and tablets
- **Interactive Charts**: Touch-enabled graphs and visualizations using fl_chart
- **Smooth Animations**: Fluid transitions and micro-interactions for enhanced user experience

## Technical Architecture

### Communication Layer
The application communicates **exclusively** with the FastAPI gateway via REST APIs. All video processing, data persistence, and business logic are handled server-side, ensuring a lightweight and responsive mobile experience.

```
                Flutter App
               /           \
        (REST:8000)     (REST:8001)
     Classic Backend   Analysis Management
            ↓               ↓
        MySQL DB       C++ Inference Engine
```

### Technology Stack

| Category | Technology |
|----------|-----------|
| **Framework** | [Flutter 3.24+](https://flutter.dev/) |
| **Language** | [Dart 3.0+](https://dart.dev/) |
| **State Management** | [Provider](https://pub.dev/packages/provider) |
| **Routing** | [go_router](https://pub.dev/packages/go_router) |
| **HTTP Client** | [http](https://pub.dev/packages/http) |
| **Data Serialization** | [json_serializable](https://pub.dev/packages/json_serializable) |
| **Charts** | [fl_chart](https://pub.dev/packages/fl_chart) |
| **Internationalization** | [intl](https://pub.dev/packages/intl) |
| **Local Storage** | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| **Video Player** | [video_player](https://pub.dev/packages/video_player) |

## Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.24 or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Version 3.0 or higher (bundled with Flutter)
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA with Flutter/Dart plugins
- **Backend**: Running instance of [Coach Pro Backend](https://github.com/your-org/coach_pro_backend)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/coach_pro_frontend.git
   cd coach_pro_frontend
   ```

2. **Configure environment variables:**
   
   Create a `.env` file in the project root:
   ```env
   BASE_URL=http://192.168.1.100:8000/api
   ANALYSIS_BASE_URL=http://192.168.1.100:8001/api
   ```
   
   Replace `192.168.1.100` with your backend server's IP address.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Generate code (for JSON serialization):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   
   Run this command whenever you modify data models in `lib/models/`.

5. **Run the application:**
   
   **For Android:**
   ```bash
   flutter run
   ```
   
   **For iOS (macOS only):**
   ```bash
   flutter run -d ios
   ```
   
   **For Web:**
   ```bash
   flutter run -d chrome
   ```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**iOS (requires macOS):**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart                   # Application entry point
├── features/                   # Feature-driven modules
│   ├── auth/                   # Authentication & login
│   ├── players/                # Player management
│   ├── matches/                # Match scheduling & history
│   ├── analysis/               # Video analysis & metrics
│   ├── formations/             # Formation editor
│   ├── settings/               # App settings & preferences
│   └── dashboard/              # Home dashboard
├── models/                     # Data models with JSON serialization
│   ├── player.dart
│   ├── match.dart
│   ├── statistics.dart
│   └── *.g.dart               # Auto-generated serialization code
├── services/                   # API communication layer
│   ├── api_service.dart       # Base HTTP client
│   ├── player_service.dart
│   ├── match_service.dart
│   └── analysis_service.dart
├── providers/                  # State management
│   ├── auth_provider.dart
│   ├── player_provider.dart
│   └── match_provider.dart
├── routes/                     # Navigation configuration
│   └── app_router.dart
├── widgets/                    # Reusable UI components
│   ├── player_card.dart
│   ├── heatmap_widget.dart
│   └── metric_chart.dart
├── l10n/                       # Localization files
│   ├── app_en.arb
│   ├── app_fr.arb
│   └── app_ar.arb
└── utils/                      # Helper functions
    ├── constants.dart
    └── formatters.dart
```

## Key User Flows

### Analyzing a Match

1. **Navigate to Matches** → Tap "Analyze New Match"
2. **Upload Video**: Select video from device gallery or record live
3. **Wait for Processing**: View real-time progress bar (typically 2-5 minutes)
4. **View Results**: Access detailed statistics, heatmaps, and player comparisons

### Building a Formation

1. **Go to Formations** → Tap "Create New Formation"
2. **Select Formation Type**: Choose from predefined templates (4-4-2, 4-3-3, etc.)
3. **Drag Players**: Assign players to positions on the pitch visualization
4. **Save**: Name and save formation for future matches

### Reviewing Player Performance

1. **Select a Match** from history
2. **View Team Statistics**: Aggregate metrics for entire team
3. **Select Individual Player**: Drill down into per-player metrics
4. **View Heatmap**: See player's movement patterns and positioning

## Configuration

### Changing Language

Language is automatically detected from device settings. To manually change:

1. Open **Settings** → **Language**
2. Select from English, Français, or العربية
3. App restarts with new language

### Theme Customization

```dart
// lib/main.dart
theme: ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.light,
  // Customize colors, fonts, etc.
)
```

## API Integration

All API calls are centralized in `lib/services/`. Example usage:

```dart
// Fetch player statistics
final stats = await PlayerService().getPlayerStats(playerId, matchId);

// Upload video for analysis
final jobId = await AnalysisService().uploadMatchVideo(videoFile);

// Check analysis status
final status = await AnalysisService().checkJobStatus(jobId);
```

API responses are automatically deserialized into type-safe Dart objects using `json_serializable`.

## Development Workflow

### Hot Reload
While running in debug mode, save files to instantly see changes:
- **Hot Reload**: Press `r` in terminal or save file (preserves state)
- **Hot Restart**: Press `R` (resets state)

### Debugging
```bash
flutter run --debug
```

Use Flutter DevTools for:
- Performance profiling
- Widget inspector
- Network monitoring

### Code Generation
After modifying models, regenerate JSON serialization:
```bash
flutter pub run build_runner watch
```

The `watch` flag automatically regenerates on file changes.

## Performance Optimization

- **Image Caching**: Network images are cached automatically
- **Lazy Loading**: Lists use `ListView.builder` for efficient rendering
- **State Preservation**: Provider ensures minimal widget rebuilds
- **Async Loading**: Data fetching uses `FutureBuilder` to prevent UI blocking

## Troubleshooting

### "Cannot connect to backend"
- Verify backend is running: `curl http://<BASE_URL>/health`
- Check firewall settings allow connections on port 8000
- For Android emulator, use `10.0.2.2` instead of `localhost`

### "JSON deserialization error"
- Ensure backend API contract matches model definitions
- Regenerate serialization code: `flutter pub run build_runner build --delete-conflicting-outputs`

### "Hot reload not working"
- Perform hot restart: Press `R`
- Some changes (e.g., to `main.dart`) require full restart

## Roadmap

- **Live Match Tracking**: Real-time analysis during ongoing matches
- **Offline Mode**: Cache match data for offline viewing
- **Team Collaboration**: Share formations and notes with coaching staff
- **Advanced Filters**: Filter statistics by time period, opponent, or conditions
- **Export Reports**: Generate PDF reports of match analysis

## Contributing

We welcome contributions! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Follow Flutter style guide and run `flutter analyze`
4. Ensure all tests pass: `flutter test`
5. Submit a pull request with detailed description

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/api_service_test.dart
```

## License

MIT License - See LICENSE file for details

## Support

For questions, bug reports, or feature requests:
- **GitHub Issues**: [github.com/your-org/coach_pro_frontend/issues](https://github.com/your-org/coach_pro_frontend/issues)
- **Email**: support@coachpro.com
- **Documentation**: [docs.coachpro.com](https://docs.coachpro.com)

---

**Built with ❤️ for football coaches worldwide**