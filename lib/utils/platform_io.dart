// Platform-specific file utilities
// This file provides a unified interface for file operations across platforms

import 'package:flutter/foundation.dart';

// Conditional import for dart:io (not available on web)
import 'dart:io' if (dart.library.html) 'package:aureascan_app/utils/io_stub.dart' as io;

/// Platform-agnostic file wrapper
class PlatformFile {
  final String path;
  
  PlatformFile(this.path);
  
  /// Create a PlatformFile from a file path (mobile) or bytes (web)
  factory PlatformFile.fromPath(String filePath) {
    if (kIsWeb) {
      throw UnsupportedError('PlatformFile.fromPath is not supported on web. Use bytes instead.');
    }
    return PlatformFile(filePath);
  }
  
  /// Get the native File object (only on mobile platforms)
  dynamic get nativeFile {
    if (kIsWeb) {
      throw UnsupportedError('Native file access is not available on web');
    }
    return io.File(path);
  }
}

