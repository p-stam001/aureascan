import 'dart:async';
import 'dart:typed_data';
import 'package:aureascan_app/models/analysis_response.dart';
import 'package:aureascan_app/services/api_service.dart';
import 'package:aureascan_app/services/websocket_service.dart';
import 'package:aureascan_app/utils/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class AnalysisState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  // File upload
  String? _fileId;
  String? _fileUrl;
  String? _originalImagePath;
  double? _imageAspectRatio;

  // Uncropped image (for display)
  String? _uncroppedImagePath; // For mobile (Android/iOS)
  Uint8List? _uncroppedImageBytes; // For web

  // Job IDs
  String? _skinJobId;
  String? _ratioJobId;
  String? _retouchJobId;

  // Results
  SkinAnalysisResults? _skinResults;
  RatioAnalysisResults? _ratioResults;
  RetouchAnalysisResults? _retouchResults;

  // Loading states
  bool _isUploading = false;
  bool _isProcessingSkin = false;
  bool _isProcessingRatio = false;
  bool _isProcessingRetouch = false;

  // Error states
  String? _uploadError;
  String? _skinError;
  String? _ratioError;
  String? _retouchError;

  // Polling timers (to allow cancellation)
  Timer? _skinPollTimer;
  Timer? _ratioPollTimer;
  Timer? _retouchPollTimer;

  // Getters
  String? get fileId => _fileId;
  String? get fileUrl => _fileUrl;
  String? get originalImagePath => _originalImagePath;
  double? get imageAspectRatio => _imageAspectRatio;
  String? get uncroppedImagePath => _uncroppedImagePath;
  Uint8List? get uncroppedImageBytes => _uncroppedImageBytes;
  String? get skinJobId => _skinJobId;
  String? get ratioJobId => _ratioJobId;
  String? get retouchJobId => _retouchJobId;
  SkinAnalysisResults? get skinResults => _skinResults;
  RatioAnalysisResults? get ratioResults => _ratioResults;
  RetouchAnalysisResults? get retouchResults => _retouchResults;
  bool get isUploading => _isUploading;
  bool get isProcessingSkin => _isProcessingSkin;
  bool get isProcessingRatio => _isProcessingRatio;
  bool get isProcessingRetouch => _isProcessingRetouch;
  String? get uploadError => _uploadError;
  String? get skinError => _skinError;
  String? get ratioError => _ratioError;
  String? get retouchError => _retouchError;

  bool get hasFile => _fileId != null;
  bool get hasSkinResults => _skinResults != null;
  bool get hasRatioResults => _ratioResults != null;
  bool get hasRetouchResults => _retouchResults != null;

  /// Set uncropped image (called before uploading cropped image)
  void setUncroppedImage({String? path, Uint8List? bytes}) {
    _uncroppedImagePath = path;
    _uncroppedImageBytes = bytes;
    _safeNotifyListeners();
  }

  /// Safely notify listeners, deferring if called during build
  void _safeNotifyListeners() {
    try {
      final scheduler = SchedulerBinding.instance;
      if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        // We're in the build phase, defer the notification
        Future.microtask(() => notifyListeners());
      } else {
        // Safe to notify immediately
        notifyListeners();
      }
    } catch (e) {
      // If scheduler binding is not available, defer to be safe
      Future.microtask(() => notifyListeners());
    }
  }

  /// Upload file
  Future<void> uploadFile(dynamic file,
      {String? filename, double? aspectRatio}) async {
    _isUploading = true;
    _uploadError = null;
    _safeNotifyListeners();
    try {
      FileUploadResponse response;
      if (file is String) {
        // File path (mobile - Android/iOS)
        final platformFile = PlatformFile.fromPath(file);
        response = await _apiService.uploadFile(platformFile);
        _originalImagePath = file;
      } else {
        // Uint8List (web)
        response =
            await _apiService.uploadFileWeb(file, filename ?? 'image.jpg');
        _originalImagePath = null;
      }

      _fileId = response.fileId;
      _fileUrl = response.fileUrl;
      _imageAspectRatio = aspectRatio;
      _isUploading = false;
      // Ensure state is fully updated before notifying
      notifyListeners();
    } catch (e) {
      _isUploading = false;
      _uploadError = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Trigger skin analysis
  Future<void> triggerSkinAnalysis() async {
    if (_fileId == null) {
      throw Exception('No file uploaded');
    }

    _isProcessingSkin = true;
    _skinError = null;
    _safeNotifyListeners();

    try {
      final jobResponse = await _apiService.triggerSkinAnalysis(_fileId!);
      _skinJobId = jobResponse.jobId;

      // Listen to WebSocket for updates
      _wsService.connectToJob(_skinJobId!).listen(
        (statusResponse) {
          if (statusResponse.isCompleted && statusResponse.results != null) {
            _skinResults =
                SkinAnalysisResults.fromJson(statusResponse.results!);
            _isProcessingSkin = false;
            // Cancel polling since WebSocket delivered the result
            _skinPollTimer?.cancel();
            _skinPollTimer = null;
            _safeNotifyListeners();
          } else if (statusResponse.isFailed) {
            _skinError = statusResponse.error ?? 'Skin analysis failed';
            _isProcessingSkin = false;
            // Cancel polling since WebSocket delivered the result
            _skinPollTimer?.cancel();
            _skinPollTimer = null;
            _safeNotifyListeners();
          }
        },
        onError: (error) {
          debugPrint('WebSocket error for skin analysis: $error');
          // Don't set error here, let polling handle it
          // Only set error if polling also fails
        },
      );

      // Also poll for status (fallback)
      _pollSkinStatus();
    } catch (e) {
      _isProcessingSkin = false;
      _skinError = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Trigger ratio analysis
  Future<void> triggerRatioAnalysis() async {
    if (_fileId == null) {
      throw Exception('No file uploaded');
    }

    _isProcessingRatio = true;
    _ratioError = null;
    _safeNotifyListeners();

    try {
      final jobResponse = await _apiService.triggerRatioAnalysis(_fileId!);
      _ratioJobId = jobResponse.jobId;

      // Listen to WebSocket for updates
      _wsService.connectToJob(_ratioJobId!).listen(
        (statusResponse) {
          if (statusResponse.isCompleted && statusResponse.results != null) {
            _ratioResults =
                RatioAnalysisResults.fromJson(statusResponse.results!);
            _isProcessingRatio = false;
            // Cancel polling since WebSocket delivered the result
            _ratioPollTimer?.cancel();
            _ratioPollTimer = null;
            _safeNotifyListeners();
          } else if (statusResponse.isFailed) {
            _ratioError = statusResponse.error ?? 'Ratio analysis failed';
            _isProcessingRatio = false;
            // Cancel polling since WebSocket delivered the result
            _ratioPollTimer?.cancel();
            _ratioPollTimer = null;
            _safeNotifyListeners();
          }
        },
        onError: (error) {
          debugPrint('WebSocket error for ratio analysis: $error');
          // Don't set error here, let polling handle it
          // Only set error if polling also fails
        },
      );

      // Also poll for status (fallback)
      _pollRatioStatus();
    } catch (e) {
      _isProcessingRatio = false;
      _ratioError = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Trigger retouch analysis
  Future<void> triggerRetouchAnalysis() async {
    if (_fileId == null) {
      throw Exception('No file uploaded');
    }

    _isProcessingRetouch = true;
    _retouchError = null;
    _safeNotifyListeners();

    try {
      final jobResponse = await _apiService.triggerRetouchAnalysis(_fileId!);
      _retouchJobId = jobResponse.jobId;

      // Listen to WebSocket for updates
      _wsService.connectToJob(_retouchJobId!).listen(
        (statusResponse) {
          if (statusResponse.isCompleted && statusResponse.results != null) {
            _retouchResults =
                RetouchAnalysisResults.fromJson(statusResponse.results!);
            _isProcessingRetouch = false;
            // Cancel polling since WebSocket delivered the result
            _retouchPollTimer?.cancel();
            _retouchPollTimer = null;
            _safeNotifyListeners();
          } else if (statusResponse.isFailed) {
            _retouchError = statusResponse.error ?? 'Retouch analysis failed';
            _isProcessingRetouch = false;
            // Cancel polling since WebSocket delivered the result
            _retouchPollTimer?.cancel();
            _retouchPollTimer = null;
            _safeNotifyListeners();
          }
        },
        onError: (error) {
          debugPrint('WebSocket error for retouch analysis: $error');
          // Don't set error here, let polling handle it
          // Only set error if polling also fails
        },
      );

      // Also poll for status (fallback)
      _pollRetouchStatus();
    } catch (e) {
      _isProcessingRetouch = false;
      _retouchError = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Poll skin status (fallback)
  Future<void> _pollSkinStatus() async {
    if (_skinJobId == null) return;

    // Cancel existing timer if any
    _skinPollTimer?.cancel();
    _skinPollTimer = null;

    _skinPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isProcessingSkin || _skinJobId == null) {
        timer.cancel();
        _skinPollTimer = null;
        return;
      }

      try {
        final status = await _apiService.getAnalysisStatus(_skinJobId!);
        if (status.isCompleted && status.results != null) {
          _skinResults = SkinAnalysisResults.fromJson(status.results!);
          _isProcessingSkin = false;
          timer.cancel();
          _skinPollTimer = null;
          _safeNotifyListeners();
        } else if (status.isFailed) {
          _skinError = status.error ?? 'Skin analysis failed';
          _isProcessingSkin = false;
          timer.cancel();
          _skinPollTimer = null;
          _safeNotifyListeners();
        }
      } catch (e) {
        // Continue polling on error, but log it
        debugPrint('Polling error for skin analysis: $e');
      }
    });
  }

  /// Poll ratio status (fallback)
  Future<void> _pollRatioStatus() async {
    if (_ratioJobId == null) return;

    // Cancel existing timer if any
    _ratioPollTimer?.cancel();
    _ratioPollTimer = null;

    _ratioPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isProcessingRatio || _ratioJobId == null) {
        timer.cancel();
        _ratioPollTimer = null;
        return;
      }

      try {
        final status = await _apiService.getAnalysisStatus(_ratioJobId!);
        if (status.isCompleted && status.results != null) {
          _ratioResults = RatioAnalysisResults.fromJson(status.results!);
          _isProcessingRatio = false;
          timer.cancel();
          _ratioPollTimer = null;
          _safeNotifyListeners();
        } else if (status.isFailed) {
          _ratioError = status.error ?? 'Ratio analysis failed';
          _isProcessingRatio = false;
          timer.cancel();
          _ratioPollTimer = null;
          _safeNotifyListeners();
        }
      } catch (e) {
        // Continue polling on error, but log it
        debugPrint('Polling error for ratio analysis: $e');
      }
    });
  }

  /// Poll retouch status (fallback)
  Future<void> _pollRetouchStatus() async {
    if (_retouchJobId == null) return;

    // Cancel existing timer if any
    _retouchPollTimer?.cancel();
    _retouchPollTimer = null;

    _retouchPollTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isProcessingRetouch || _retouchJobId == null) {
        timer.cancel();
        _retouchPollTimer = null;
        return;
      }

      try {
        final status = await _apiService.getAnalysisStatus(_retouchJobId!);
        if (status.isCompleted && status.results != null) {
          _retouchResults = RetouchAnalysisResults.fromJson(status.results!);
          _isProcessingRetouch = false;
          timer.cancel();
          _retouchPollTimer = null;
          _safeNotifyListeners();
        } else if (status.isFailed) {
          _retouchError = status.error ?? 'Retouch analysis failed';
          _isProcessingRetouch = false;
          timer.cancel();
          _retouchPollTimer = null;
          _safeNotifyListeners();
        }
      } catch (e) {
        // Continue polling on error, but log it
        debugPrint('Polling error for retouch analysis: $e');
      }
    });
  }

  /// Reset state
  void reset() {
    // Cancel all polling timers
    _skinPollTimer?.cancel();
    _skinPollTimer = null;
    _ratioPollTimer?.cancel();
    _ratioPollTimer = null;
    _retouchPollTimer?.cancel();
    _retouchPollTimer = null;

    _fileId = null;
    _fileUrl = null;
    _originalImagePath = null;
    _imageAspectRatio = null;
    _uncroppedImagePath = null;
    _uncroppedImageBytes = null;
    _skinJobId = null;
    _ratioJobId = null;
    _retouchJobId = null;
    _skinResults = null;
    _ratioResults = null;
    _retouchResults = null;
    _isUploading = false;
    _isProcessingSkin = false;
    _isProcessingRatio = false;
    _isProcessingRetouch = false;
    _uploadError = null;
    _skinError = null;
    _ratioError = null;
    _retouchError = null;
    _wsService.disconnectAll();
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    // Cancel all polling timers
    _skinPollTimer?.cancel();
    _ratioPollTimer?.cancel();
    _retouchPollTimer?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}
