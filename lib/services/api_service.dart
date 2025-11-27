import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:aureascan_app/models/analysis_response.dart';
import 'package:aureascan_app/utils/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Default to production API, can be overridden via .env file
  final String apiUrl = dotenv.env['API_BASE_URL'] ?? 'https://aureascan.ai';
  final String basePath = '/api/v1';

  String get baseUrl => '$apiUrl$basePath';

  /// Upload an image file to the backend (mobile platforms: Android/iOS)
  Future<FileUploadResponse> uploadFile(PlatformFile imageFile) async {
    print("Upload file: ${imageFile.path}");
    print("Upload file: $baseUrl");
    try {
      final uri = Uri.parse("$baseUrl/files/upload");
      final request = http.MultipartRequest('POST', uri);

      request.headers['accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Upload response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        return FileUploadResponse.fromJson(jsonResponse);
      } else {
        debugPrint('Upload failed: ${response.statusCode} - $responseBody');
        throw Exception(
            'Failed to upload file: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      // Provide user-friendly error messages for common network issues
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('no address associated with hostname') ||
          errorString.contains('socketexception')) {
        throw Exception(
            'Erro de conexão: Verifique sua conexão com a internet e tente novamente.');
      } else if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        throw Exception(
            'Tempo de conexão esgotado. Verifique sua internet e tente novamente.');
      } else if (errorString.contains('connection refused') ||
          errorString.contains('connection reset')) {
        throw Exception(
            'Não foi possível conectar ao servidor. Tente novamente mais tarde.');
      }
      throw Exception('Erro ao enviar imagem: ${e.toString()}');
    }
  }

  /// Upload an image file from bytes (for web)
  Future<FileUploadResponse> uploadFileWeb(
      Uint8List bytes, String filename) async {
    try {
      final uri = Uri.parse("$baseUrl/files/upload");
      final request = http.MultipartRequest('POST', uri);

      request.headers['accept'] = 'application/json';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        return FileUploadResponse.fromJson(jsonResponse);
      } else {
        debugPrint('Upload failed: ${response.statusCode} - $responseBody');
        throw Exception(
            'Failed to upload file: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      // Provide user-friendly error messages for common network issues
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('no address associated with hostname') ||
          errorString.contains('socketexception')) {
        throw Exception(
            'Erro de conexão: Verifique sua conexão com a internet e tente novamente.');
      } else if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        throw Exception(
            'Tempo de conexão esgotado. Verifique sua internet e tente novamente.');
      } else if (errorString.contains('connection refused') ||
          errorString.contains('connection reset')) {
        throw Exception(
            'Não foi possível conectar ao servidor. Tente novamente mais tarde.');
      }
      throw Exception('Erro ao enviar imagem: ${e.toString()}');
    }
  }

  /// Trigger skin analysis
  Future<AnalysisJobResponse> triggerSkinAnalysis(String fileId) async {
    try {
      final uri = Uri.parse("$baseUrl/analysis/skin");
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({'file_id': fileId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AnalysisJobResponse.fromJson(jsonResponse);
      } else {
        debugPrint(
            'Skin analysis trigger failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to trigger skin analysis: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Skin analysis error: $e');
      throw Exception('Failed to trigger skin analysis: $e');
    }
  }

  /// Trigger ratio analysis
  Future<AnalysisJobResponse> triggerRatioAnalysis(String fileId) async {
    try {
      final uri = Uri.parse("$baseUrl/analysis/ratio");
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({'file_id': fileId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AnalysisJobResponse.fromJson(jsonResponse);
      } else {
        debugPrint(
            'Ratio analysis trigger failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to trigger ratio analysis: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Ratio analysis error: $e');
      throw Exception('Failed to trigger ratio analysis: $e');
    }
  }

  /// Trigger retouch analysis
  Future<AnalysisJobResponse> triggerRetouchAnalysis(String fileId) async {
    try {
      final uri = Uri.parse("$baseUrl/analysis/retouch");
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({'file_id': fileId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AnalysisJobResponse.fromJson(jsonResponse);
      } else {
        debugPrint(
            'Retouch analysis trigger failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to trigger retouch analysis: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Retouch analysis error: $e');
      throw Exception('Failed to trigger retouch analysis: $e');
    }
  }

  /// Get analysis status
  Future<AnalysisStatusResponse> getAnalysisStatus(String jobId) async {
    try {
      final uri = Uri.parse("$baseUrl/analysis/status/$jobId");
      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return AnalysisStatusResponse.fromJson(jsonResponse);
      } else {
        debugPrint(
            'Status check failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to get analysis status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Status check error: $e');
      throw Exception('Failed to get analysis status: $e');
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse("$baseUrl/health");
      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );
      final isHealthy = response.statusCode == 200;
      if (!isHealthy) {
        debugPrint('Health check failed: ${response.statusCode}');
      }
      return isHealthy;
    } catch (e) {
      debugPrint('Health check error: $e');
      return false;
    }
  }
}
