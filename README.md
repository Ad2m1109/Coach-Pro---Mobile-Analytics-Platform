# Football Coach Frontend (Flutter)

Mobile app for team management, match workflows, and video analysis history/preview.

## Current Architecture

```text
Flutter App
  -> Backend API (FastAPI) :8000
  -> Analysis API (FastAPI) :8001
       -> Tracking Engine (gRPC) :50051
```

- `:8000` handles core app data (auth, teams, players, matches, notes, settings).
- `:8001` handles upload + analysis lifecycle + media streaming endpoints.

## Main Features

- Authentication and role-based access.
- Team/player/match management.
- Analyze screen:
  - Upload video
  - Track analysis status/history
  - Preview generated videos/images/json
  - Fullscreen preview for videos/images
  - Delete failed analysis rows

## Environment

Create `frontend/.env`:

```env
BASE_URL=http://<SERVER_IP>:8000/api
localApiUrl=http://localhost:8000/api
ANALYSIS_BASE_URL=http://<SERVER_IP>:8001/api
localAnalysisApiUrl=http://localhost:8001/api
```

Use LAN IP for physical Android devices.

## Run

```bash
cd frontend
flutter pub get
flutter run
```

## Relevant Folders

```text
frontend/lib/
├── features/
│   ├── analyze/
│   ├── matches/
│   ├── match_details/
│   ├── players/
│   └── settings/
├── services/
│   ├── api_client.dart
│   ├── analysis_service.dart
│   ├── video_analysis_service.dart
│   └── ...
├── models/
├── widgets/
└── main.dart
```

## Analysis Media Flow

1. User uploads video from Analyze page.
2. App calls `POST /api/analyze_match` on `:8001`.
3. History uses `GET /api/analysis_history`.
4. Media previews use:
   - `GET /api/analysis/stream` (video)
   - `GET /api/analysis/files` (images/files)
   - `GET /api/analysis/files/json` (json preview)

## Notes

- Android cleartext HTTP must be allowed in app config when using `http://` LAN URLs.
- Analysis file paths are now generated from analysis ID and served by backend; frontend does not read local filesystem directly.
