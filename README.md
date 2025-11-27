# AureaScanAI Frontend

A cross-platform Flutter app for facial structure and skin analysis using AI-powered backend services.

## Features

- **Camera Capture**: Take photos with front-facing camera
- **Facial Ratio Analysis**: Analyze facial proportions and golden ratios
- **Skin Analysis**: Comprehensive skin condition analysis including:
  - Wrinkles (forehead, glabellar, crowfeet, periocular, nasolabial, marionette, whole)
  - Pores (forehead, nose, cheek, whole)
  - Acne detection
  - Oiliness, moisture, redness, age spots
  - Overall skin score and skin age
- **Photo Enhancement (Retouch)**: See potential results with AI-enhanced photos
- **Treatment Suggestions**: Professional and home treatment recommendations
- **Real-time Updates**: WebSocket support for live job status updates
- **Cross-platform**: Works on Android, iOS, and Web

## Architecture

The app uses a modern Flutter architecture with:

- **State Management**: Provider pattern for state management
- **API Service**: RESTful API client for backend communication
- **WebSocket Service**: Real-time job status updates
- **Models**: Strongly-typed data models matching backend schemas
- **Screens**: Clean, modular screen components

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- Dart 3.0+
- Backend API running (see `aureascanai-backend` README)

### Setup

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd aureascan-frontend
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure environment variables:**
   - Create `assets/.env` file:
     ```env
     # Production API (default if not specified)
     API_BASE_URL=https://aureascan.ai
     ```
   - For local development, use:
     ```env
     API_BASE_URL=http://localhost:8000
     ```
   - The `.env` file should not be committed to version control (add to `.gitignore`)
   - **Note:** The app defaults to `https://aureascan.ai` if no `.env` file is provided

4. **Run the app:**
   - **Web:**
     ```sh
     flutter run -d chrome
     ```
   - **Android/iOS:**
     ```sh
     flutter run
     ```

## App Flow

1. **Splash Screen** → Shows app branding
2. **Onboarding Screen** → Introduction and terms
3. **Camera Screen** → Capture photo
   - Uploads image to backend
   - Triggers skin and ratio analyses
4. **Facial Structure Screen** → Shows ratio analysis results
   - Horizontal thirds and vertical fifths overlays
5. **Skin Analysis Screen** → Shows comprehensive skin analysis
   - Detailed metrics for all skin features
   - Overall score and skin age
6. **Treatment Suggestions Screen** → Professional and home treatments
7. **Potential Results Screen** → Before/after retouch comparison
   - Automatically triggers retouch analysis if needed

## API Integration

The app integrates with the `aureascanai-backend` API:

- **POST /api/v1/files/upload** - Upload image
- **POST /api/v1/analysis/skin** - Trigger skin analysis
- **POST /api/v1/analysis/ratio** - Trigger ratio analysis
- **POST /api/v1/analysis/retouch** - Trigger retouch analysis
- **GET /api/v1/analysis/status/{job_id}** - Poll job status
- **WS /ws/{job_id}** - WebSocket for real-time updates

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── analysis_response.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── camera_screen.dart
│   ├── facial_structure_screen.dart
│   ├── skin_analysis_screen.dart
│   ├── treatment_suggestions_screen.dart
│   └── potential_results_screen.dart
├── services/                  # API and WebSocket services
│   ├── api_service.dart
│   └── websocket_service.dart
├── state/                     # State management
│   └── analysis_state.dart
├── utils/                     # Utilities
│   ├── app_colors.dart
│   └── app_theme.dart
└── widgets/                   # Reusable widgets
    ├── gradient_button.dart
    └── gradient_tab_indicator.dart
```

## Dependencies

- `http` - HTTP client for API calls
- `web_socket_channel` - WebSocket support
- `provider` - State management
- `camera` - Camera functionality
- `cached_network_image` - Image caching
- `flutter_dotenv` - Environment variables
- `image_gallery_saver` - Save images to gallery
- `permission_handler` - Handle permissions

## Environment Variables

The app uses `flutter_dotenv` to load environment variables from `assets/.env`:

```env
# Production API (default)
API_BASE_URL=https://aureascan.ai

# For local development:
# API_BASE_URL=http://localhost:8000
```

**Important:** 
- If no `.env` file is provided, the app defaults to the production API at `https://aureascan.ai`
- The API documentation is available at: https://aureascan.ai/docs#/
- All API endpoints are under `/api/v1/`

Access in code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
final apiUrl = dotenv.env['API_BASE_URL'];
```

### API Endpoints

The app connects to the following endpoints:

- **File Upload:** `POST /api/v1/files/upload`
- **Skin Analysis:** `POST /api/v1/analysis/skin`
- **Ratio Analysis:** `POST /api/v1/analysis/ratio`
- **Retouch Analysis:** `POST /api/v1/analysis/retouch`
- **Status Check:** `GET /api/v1/analysis/status/{job_id}`
- **Health Check:** `GET /api/v1/health`
- **WebSocket:** `wss://aureascan.ai/ws/{job_id}` (for real-time status updates)

## UI/UX Style

The app maintains a consistent design language:

- **Colors**: Gold/amber primary color (#DBB251)
- **Typography**: Inter font family
- **Components**: Rounded corners, gradient buttons, card-based layouts
- **Navigation**: Stack-based navigation with back buttons

## Error Handling

The app includes comprehensive error handling:

- Network errors are caught and displayed to users
- Loading states are shown during async operations
- Fallback polling if WebSocket fails
- Graceful degradation for missing data

## Development

### Running Tests

```sh
flutter test
```

### Building for Production

**Android:**
```sh
flutter build apk --release
```

**iOS:**
```sh
flutter build ios --release
```

**Web:**
```sh
flutter build web --release
```

## Troubleshooting

### WebSocket Connection Issues

If WebSocket connections fail, the app automatically falls back to polling the status endpoint every 2 seconds.

### Image Upload Issues

- Ensure backend is running and accessible
- Check `API_BASE_URL` in `.env` file (defaults to `https://aureascan.ai` if not set)
- Verify CORS settings for web platform
- Check network connectivity and firewall settings
- Review debug logs for detailed error messages

### Camera Permissions

On mobile platforms, ensure camera permissions are granted. The app requests permissions automatically.

## License

MIT
