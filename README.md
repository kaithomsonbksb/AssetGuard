# AssetGuard

Please note, this read me file has been generated using AI

A cross-platform Flutter proof of concept for offline-first field inspection management. Built as a university assignment to demonstrate mobile/desktop app development with local SQLite storage and REST API sync.

## What it does

Engineers log in
View a list of inspection jobs 
Fill out inspection reports with optional photo attachments
Sync completed records to a Flask backend server

The app works fully offline
Inspections are saved locally first
Synced to the server when connectivity is available

## Demo credentials

```
Email:    engineer@assetguard.com
Password: password123
```

## Running the Flask sync server

The server stores synced inspection records and serves a monitoring dashboard.

```bash
# Install dependencies (one time)
pip install flask flask-cors

# Start the server
python server.py
```

The server runs on `http://localhost:5000`. Open that URL in a browser to see the dashboard.

**Note:** if you are testing on a physical Android device (not the emulator), change the URL in `lib/services/api_service.dart` from `http://10.0.2.2:5000` to your machine's local IP address, e.g. `http://192.168.1.x:5000`.

## Running the Flutter app

```bash
# Install dependencies
flutter pub get

# Run on Windows desktop
flutter run -d windows

# Run on Android (emulator or device)
flutter run -d android
```

## How to test the sync workflow

1. Start the Flask server (`python server.py`)
2. Log in and tap a job to open the inspection form
3. Fill in the result and notes, optionally add photos, then save
4. The job list shows the record as **Pending sync** (amber chip)
5. Press the sync button (⟳) in the top right — the record uploads to the server
6. The chip changes to **Synced** (green)
7. Refresh `http://localhost:5000` to see the record in the dashboard

To test the failure path, stop the server before pressing sync. The chip will turn red (**Failed**). Restart the server and sync again to retry.

## Project structure

```
lib/
├── database/
│   └── database_helper.dart   # SQLite setup and all CRUD operations
├── models/
│   ├── job.dart               # Job model
│   ├── inspection_item.dart   # Inspection record model
│   └── attachment.dart        # Photo attachment model
├── screens/
│   ├── login_screen.dart
│   ├── job_list_screen.dart
│   ├── inspection_detail_screen.dart
│   └── sync_status_screen.dart
├── services/
│   └── api_service.dart       # HTTP calls to the Flask server
└── sync/
    └── sync_manager.dart      # Orchestrates the sync workflow
server.py                      # Flask sync server
```
