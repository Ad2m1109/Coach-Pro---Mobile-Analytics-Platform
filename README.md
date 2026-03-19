# Football Coach Frontend

## Abstract
This frontend is the operator-facing Flutter client for the Football Coach platform. It combines team administration, match management, player scouting views, asynchronous video-analysis workflows, real-time tactical alerts, and an embedded AI assistant inside one multi-platform application. The codebase currently contains roughly 115 Dart files under `lib/`, organized around feature modules, domain models, service clients, and a small design system.

From the code, the frontend is best understood as a thin but stateful orchestration layer over two HTTP APIs and one WebSocket channel:

- the classic backend API for team, match, player, settings, and assistant features
- the dedicated analysis API for video upload, status polling, file streaming, and segment timelines
- the tactical-alert WebSocket for live dashboard updates during or after analysis

## System Role
The frontend sits at the top of the platform stack:

```text
Flutter App
  -> Backend API      (:8000 /api)   for CRUD, auth, RBAC, assistant, alerts metadata
  -> Analysis API     (:8001 /api)   for upload, analysis history, files, segments, retry/cancel
  -> WebSocket        (:8000 /ws)    for live tactical alerts
  -> Local storage                 for JWT, theme, locale, assistant bubble visibility
```

Operationally, the app is designed for coaches, analysts, assistants, and player-level viewers. Role-sensitive navigation is enforced in the UI by `AuthService`, which decodes JWT claims and hides or disables privileged surfaces.

## Technical Profile

| Area | Implementation |
| --- | --- |
| Framework | Flutter with Dart `>=3.8.0 <4.0.0` |
| State management | `provider` with `ChangeNotifier` services |
| Navigation | `go_router` with `ShellRoute` for authenticated shell screens |
| Networking | `http` through a shared `ApiClient` abstraction |
| Media | `image_picker` for uploads, `video_player` for previews and tactical dashboards |
| Persistence | `shared_preferences` for JWT, theme, locale, and assistant bubble state |
| Localization | `flutter_localizations`, `intl`, generated AR/EN/FR localizations |
| Data serialization | `json_annotation` and generated `*.g.dart` files |
| Visualization | `fl_chart`, custom painters, custom pitch/network widgets |

## Source Layout

```text
frontend/
├── lib/
│   ├── core/design_system/      # colors, spacing, theme, typography
│   ├── features/                # route-level product modules
│   ├── l10n/                    # generated localizations + ARB files
│   ├── models/                  # domain objects and JSON serializers
│   ├── routes/                  # go_router configuration
│   ├── services/                # API clients, notifiers, realtime orchestration
│   └── widgets/                 # shared widgets and navigation shell
├── assets/                      # splash/art assets and launcher icon source
├── android/ ios/ linux/ web/ windows/
└── .env                         # runtime endpoint configuration
```

The application logic lives almost entirely under `lib/`; the platform directories are standard Flutter wrappers rather than custom business logic.

## Boot Sequence
The startup path in `lib/main.dart` is a good summary of the application architecture:

1. Flutter bindings are initialized.
2. `.env` is loaded through `flutter_dotenv`.
3. The app selects base URLs differently for web and mobile:
   - web prefers `localApiUrl` and `localAnalysisApiUrl`
   - mobile prefers `BASE_URL` and `ANALYSIS_BASE_URL`
4. Two `ApiClient` instances are created:
   - one for the classic backend
   - one for the dedicated analysis backend
5. `AuthService` restores the JWT from `SharedPreferences`, injects the token into both API clients, and fetches `/users/me`.
6. Theme, locale, and assistant-bubble preferences are restored.
7. Providers are registered with `MultiProvider`.
8. `MaterialApp.router` is launched with a timed splash overlay and dynamic router redirection.

This makes the frontend a composed runtime rather than a passive widget tree: transport, auth, settings, and feature-level notifiers are all assembled before the first authenticated screen renders.

## Architectural Layers

### 1. Design System
`lib/core/design_system/` defines the visual primitives:

- `AppColors`: emerald primary palette, crimson secondary palette, light and dark neutral surfaces
- `AppSpacing`: shared spacing and border-radius tokens
- `AppTypography`: shared text styles
- `AppTheme`: Material 3 light and dark themes built from the tokens above

The theme layer is intentionally lightweight. Most product differentiation happens in feature widgets rather than through a large token system.

### 2. Routing and Shell Navigation
`lib/routes/app_router.dart` uses `GoRouter` with two routing zones:

- unauthenticated routes:
  - `/login`
  - `/register`
- authenticated shell routes:
  - `/strategie`
  - `/matches`
  - `/players`
  - `/analyze`
  - `/settings`

The shell is implemented by `ScaffoldWithNavBar`, which contributes:

- a bottom navigation bar
- a persistent floating AI assistant bubble overlay
- role-aware nav visibility

The Analyze tab is hidden for users whose decoded role resolves to `player`.

### 3. Service Layer
The service layer is the real application backbone.

Core cross-cutting services:

- `ApiClient`: shared HTTP abstraction, auth-header injection, query-parameter handling, API exception normalization
- `AuthService`: JWT persistence, `/token` login, `/register`, `/users/me`, RBAC claim parsing, logout
- `ThemeNotifier`: theme persistence and toggling
- `LocaleNotifier`: locale persistence
- `ChatBubbleNotifier`: visibility and overlay-open state for the embedded assistant

Domain CRUD services:

- `TeamService`
- `MatchService`
- `PlayerService`
- `StaffService`
- `EventService`
- `FormationService`
- `MatchLineupService`
- `PlayerMatchStatisticsService`
- `NoteService`
- `ReunionService`
- `TrainingSessionService`

Analysis and realtime services:

- `VideoAnalysisService`: upload, progress polling, SSE segment subscription, cancel, retry
- `AnalysisService`: analysis history, file URLs, JSON preview loading, segment listing
- `TacticalAlertService`: WebSocket connection, alert history refresh, decision feedback, decision metrics
- `AssistantService`: `/assistant/query` integration

### 4. Model Layer
The models mirror backend payloads and are intentionally explicit. Representative entities include:

- identity and organization: `User`, `Staff`, `Team`
- competition: `Match`, `Event`, `MatchDetails`, `MatchLineup`, `MatchEvent`
- player analysis: `Player`, `PlayerMatchStatistics`, `MatchTeamStatistics`
- asynchronous analysis: `AnalysisReport`, `AnalysisSegment`, `TacticalAlert`
- collaboration: `MatchNote`, `ChatMessage`, `Reunion`, `TrainingSession`

Many models use generated serializers, which makes the frontend strongly coupled to backend payload shape but simpler to reason about during debugging.

## Feature Modules

| Feature | Primary screens | Backing services | Purpose |
| --- | --- | --- | --- |
| Auth | `login_screen.dart`, `register_screen.dart` | `AuthService` | Entry point and token bootstrap |
| Strategie | `strategie_screen.dart`, training and reunion screens | `TrainingSessionService`, `ReunionService` | Planning and team operations |
| Matches | `matches_screen.dart`, add-match/event, match details | `MatchService`, `EventService`, `MatchLineupService`, `FormationService` | Schedule, filter, inspect, and enrich matches |
| Players | `players_screen.dart`, add-player, profile/details/statistics | `PlayerService`, `PlayerMatchStatisticsService` | Roster management and player analytics |
| Analyze | `analyze_screen.dart`, new-analysis, history, preview | `VideoAnalysisService`, `AnalysisService`, `NoteService` | Upload video, watch progress, inspect segment outputs |
| Match Statistics | `match_statistics_screen.dart`, tactical dashboard widgets | `AnalysisService`, `TacticalAlertService` | Post-analysis visual analytics and realtime tactical review |
| Assistant | `chat_assistant_page.dart`, floating bubble | `AssistantService`, `ChatBubbleNotifier` | Conversational tactical Q&A |
| Settings | settings sub-screens, staff list, preferences, about | `AuthService`, `ChatBubbleNotifier`, domain services | Admin tasks and local preferences |

## Important User Flows

### Authentication and Role Gating
The auth flow is straightforward but important:

1. The user submits credentials to `/token`.
2. The backend returns an RS256-signed JWT.
3. `AuthService` stores the token and parses claims such as:
   - `user_type`
   - `staff_id`
   - `team_id`
   - `permission_level`
   - `app_role`
   - `app_permissions`
4. The router refreshes, redirects away from auth pages, and enables the shell.
5. Shell navigation and screen actions check permissions using helper getters like `canManagePlayers`, `canManageReunions`, and `hasPermission`.

### Match Analysis Workflow
The analysis flow is the most sophisticated frontend sequence in the repository:

1. The user selects a video with `image_picker`.
2. `VideoAnalysisService.uploadAndAnalyzeVideo()` streams the multipart upload to the analysis backend.
3. Upload progress is shown in real time.
4. After the backend responds with an analysis id:
   - the service starts SSE consumption from `/analysis/{analysis_id}/segments/stream`
   - the service starts polling `/analysis_status/{analysis_id}`
5. New segment cards are inserted into the UI as they arrive.
6. Completed assets are later browsed through the history screen and preview pages.
7. File playback uses authenticated URLs generated by `AnalysisService`.

This is a hybrid streaming architecture: upload and status are request-response, segments are SSE, and tactical events are handled separately through WebSockets.

### Tactical Dashboard Workflow
The tactical dashboard on the match-statistics side combines three different data sources:

1. REST fetch of latest analysis metadata for the selected match
2. Authenticated video streaming for tracking previews
3. WebSocket subscription to `/ws/alerts/{match_id}` via `TacticalAlertService`

The dashboard also supports manual video-to-match synchronization by writing a "video anchor" through `MatchService`. Once anchored, clicking a tactical alert seeks the analysis video to the inferred timestamp.

### Assistant Workflow
The AI assistant can be opened in two ways:

- as a dedicated page
- as a floating overlay available from shell pages

Messages are posted to `/assistant/query`, and typing/loading state is handled locally inside the chat screen. The assistant feature is deliberately lightweight on the client; almost all reasoning lives in the backend RAG stack.

## Realtime Interfaces

| Interface | Consumer | Purpose |
| --- | --- | --- |
| `GET /api/analysis/{id}/segments/stream` | `VideoAnalysisService` | Live segment timeline during analysis |
| `GET /api/analysis_status/{id}` | `VideoAnalysisService` | Polling progress and live stats |
| `GET /ws/alerts/{match_id}` | `TacticalAlertService` | Live tactical alert packets |
| `POST /api/decision/feedback` or `/decision/feedback` | `TacticalAlertService` | Coach feedback on recommendations |
| `GET /api/decision/metrics` or `/decision/metrics` | `TacticalAlertService` | Decision-effectiveness dashboards |

## Environment Configuration
The frontend expects a `.env` file. The code reads the following keys:

```dotenv
BASE_URL=http://localhost:8000/api
ANALYSIS_BASE_URL=http://localhost:8001/api
localApiUrl=http://localhost:8000/api
localAnalysisApiUrl=http://localhost:8001/api
```

Notes:

- web builds prefer `localApiUrl` and `localAnalysisApiUrl`
- non-web builds use `BASE_URL` and `ANALYSIS_BASE_URL`
- the auth token is reused across both backend surfaces

## Local Development

### Prerequisites

- Flutter SDK compatible with Dart 3.8
- A running classic backend on port `8000`
- A running analysis backend on port `8001`
- Optional: the tracking engine running behind the analysis backend for end-to-end analysis

### Setup

```bash
cd frontend
flutter pub get
```

If model classes change and generated serializers must be refreshed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
cd frontend
flutter run -d chrome
```

For Android or desktop targets, use the standard Flutter device selectors.

## Strengths Observed in the Code

- Clean separation between transport concerns and feature widgets
- Explicit domain models that largely mirror backend contracts
- Role-aware UI behavior without over-complicating routing
- Good use of multiple transport modes: HTTP, SSE, and WebSocket
- Internationalization is built in rather than retrofitted
- The analysis workflow is product-rich: upload progress, segment streaming, preview playback, history, retry, and tactical overlays all coexist coherently

## Architectural Tensions and Current Limits

- Several large screens, especially analysis and dashboard screens, combine presentation and orchestration state in one widget, which raises maintenance cost.
- The app has limited visible automated test coverage in the frontend repository itself.
- The design system is intentionally small; visual consistency depends heavily on each feature module using shared widgets correctly.
- The analysis UI assumes backend endpoint compatibility very closely, so contract drift on the backend will surface quickly in the client.
- There is no checked-in frontend `.env.example`, even though endpoint configuration is mandatory.

## Suggested Reading Order
For a new contributor, the fastest high-signal walkthrough is:

1. `lib/main.dart`
2. `lib/routes/app_router.dart`
3. `lib/services/api_client.dart`
4. `lib/services/auth_service.dart`
5. `lib/services/video_analysis_service.dart`
6. `lib/services/tactical_alert_service.dart`
7. `lib/features/analyze/...`
8. `lib/features/match_statistics/presentation/tactical_dashboard_page.dart`

That sequence reproduces the actual runtime stack from bootstrap to the most distinctive product flows.
