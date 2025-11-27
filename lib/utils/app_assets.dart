/// Central registry for all asset paths used in the application.
/// 
/// This class provides a single source of truth for asset paths,
/// making it easier to maintain and refactor asset references.
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // Images
  static const String faceOutline = 'assets/images/face_outline.png';

  // Environment
  static const String envFile = 'assets/.env';

  // Fonts
  /// Inter font family name (as declared in pubspec.yaml)
  static const String fontFamily = 'Inter';
}

