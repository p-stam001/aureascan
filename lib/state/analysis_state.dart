import 'dart:async';
import 'package:aureascan_app/models/analysis_response.dart';
import 'package:aureascan_app/services/api_service.dart';
import 'package:aureascan_app/services/websocket_service.dart';
import 'package:aureascan_app/utils/platform_io.dart';
import 'package:flutter/foundation.dart';

class AnalysisState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  // File upload
  String? _fileId;
  String? _fileUrl;
  String? _originalImagePath;

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

  // Getters
  String? get fileId => _fileId;
  String? get fileUrl => _fileUrl;
  String? get originalImagePath => _originalImagePath;
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

  /// Upload file
  Future<void> uploadFile(dynamic file, {String? filename}) async {
    _isUploading = true;
    _uploadError = null;
    notifyListeners();
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
      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _isUploading = false;
      _uploadError = e.toString();
      notifyListeners();
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
    notifyListeners();

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
            notifyListeners();
          } else if (statusResponse.isFailed) {
            _skinError = statusResponse.error ?? 'Skin analysis failed';
            _isProcessingSkin = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _skinError = error.toString();
          _isProcessingSkin = false;
          notifyListeners();
        },
      );

      // Also poll for status (fallback)
      _pollSkinStatus();
    } catch (e) {
      _isProcessingSkin = false;
      _skinError = e.toString();
      notifyListeners();
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
    notifyListeners();

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
            notifyListeners();
          } else if (statusResponse.isFailed) {
            _ratioError = statusResponse.error ?? 'Ratio analysis failed';
            _isProcessingRatio = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _ratioError = error.toString();
          _isProcessingRatio = false;
          notifyListeners();
        },
      );

      // Also poll for status (fallback)
      _pollRatioStatus();
    } catch (e) {
      _isProcessingRatio = false;
      _ratioError = e.toString();
      notifyListeners();
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
    notifyListeners();

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
            notifyListeners();
          } else if (statusResponse.isFailed) {
            _retouchError = statusResponse.error ?? 'Retouch analysis failed';
            _isProcessingRetouch = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _retouchError = error.toString();
          _isProcessingRetouch = false;
          notifyListeners();
        },
      );

      // Also poll for status (fallback)
      _pollRetouchStatus();
    } catch (e) {
      _isProcessingRetouch = false;
      _retouchError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Poll skin status (fallback)
  Future<void> _pollSkinStatus() async {
    if (_skinJobId == null) return;

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isProcessingSkin) {
        timer.cancel();
        return;
      }

      try {
        final status = await _apiService.getAnalysisStatus(_skinJobId!);
        if (status.isCompleted && status.results != null) {
          _skinResults = SkinAnalysisResults.fromJson(status.results!);
          _isProcessingSkin = false;
          timer.cancel();
          notifyListeners();
        } else if (status.isFailed) {
          _skinError = status.error ?? 'Skin analysis failed';
          _isProcessingSkin = false;
          timer.cancel();
          notifyListeners();
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  /// Poll ratio status (fallback)
  Future<void> _pollRatioStatus() async {
    if (_ratioJobId == null) return;

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isProcessingRatio) {
        timer.cancel();
        return;
      }

      try {
        final status = await _apiService.getAnalysisStatus(_ratioJobId!);
        if (status.isCompleted && status.results != null) {
          _ratioResults = RatioAnalysisResults.fromJson(status.results!);
          _isProcessingRatio = false;
          timer.cancel();
          notifyListeners();
        } else if (status.isFailed) {
          _ratioError = status.error ?? 'Ratio analysis failed';
          _isProcessingRatio = false;
          timer.cancel();
          notifyListeners();
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  /// Poll retouch status (fallback)
  Future<void> _pollRetouchStatus() async {
    if (_retouchJobId == null) return;

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isProcessingRetouch) {
        timer.cancel();
        return;
      }

      try {
        final status = await _apiService.getAnalysisStatus(_retouchJobId!);
        if (status.isCompleted && status.results != null) {
          _retouchResults = RetouchAnalysisResults.fromJson(status.results!);
          _isProcessingRetouch = false;
          timer.cancel();
          notifyListeners();
        } else if (status.isFailed) {
          _retouchError = status.error ?? 'Retouch analysis failed';
          _isProcessingRetouch = false;
          timer.cancel();
          notifyListeners();
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  /// Reset state
  void reset() {
    _fileId = null;
    _fileUrl = null;
    _originalImagePath = null;
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
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}
