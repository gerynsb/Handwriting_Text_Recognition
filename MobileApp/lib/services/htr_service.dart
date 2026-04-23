import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HTRService {
  static const String _apiUrlKey = 'api_url';
  static const String _defaultBaseUrl = String.fromEnvironment(
    'HTR_API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  final http.Client _client;
  final String? _baseUrlOverride;
  static const Map<String, String> _defaultHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  HTRService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrlOverride = _normalizeBaseUrl(baseUrl);

  static String _normalizeBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    return url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static bool isValidApiBaseUrl(String url) {
    final normalized = _normalizeBaseUrl(url);
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, _normalizeBaseUrl(url));
  }

  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _normalizeBaseUrl(prefs.getString(_apiUrlKey));
    if (saved.isNotEmpty) {
      return saved;
    }
    return _defaultBaseUrl;
  }

  Future<String> _resolveBaseUrl() async {
    if (_baseUrlOverride != null && _baseUrlOverride!.isNotEmpty) {
      return _baseUrlOverride!;
    }
    return getApiBaseUrl();
  }

  /// Check API health
  Future<bool> healthCheck() async {
    try {
      final baseUrl = await _resolveBaseUrl();
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/health'),
            headers: _defaultHeaders,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  /// Get model information
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final baseUrl = await _resolveBaseUrl();
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/model/info'),
            headers: _defaultHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get model info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Model info error: $e');
    }
  }

  /// Recognize single line
  Future<String> recognizeLine(
    XFile image, {
    bool useBeamSearch = true,
  }) async {
    try {
      final baseUrl = await _resolveBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/recognize/line'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      request.fields['use_beam_search'] = useBeamSearch.toString();
      request.headers.addAll(_defaultHeaders);

      final response = await request.send().timeout(
            const Duration(seconds: 30),
          );

      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['text'] ?? '';
      } else {
        throw Exception(
          jsonResponse['error'] ?? 'Recognition failed',
        );
      }
    } catch (e) {
      throw Exception('Line recognition error: $e');
    }
  }

  /// Recognize paragraph (multiple lines)
  Future<List<String>> recognizeParagraph(
    XFile image, {
    String segmentationMethod = 'projection',
    bool useBeamSearch = true,
  }) async {
    try {
      final baseUrl = await _resolveBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/recognize/paragraph'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      request.fields['segmentation_method'] = segmentationMethod;
      request.fields['use_beam_search'] = useBeamSearch.toString();
      request.headers.addAll(_defaultHeaders);

      final response = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return List<String>.from(jsonResponse['lines'] ?? []);
      } else {
        throw Exception(
          jsonResponse['error'] ?? 'Recognition failed',
        );
      }
    } catch (e) {
      throw Exception('Paragraph recognition error: $e');
    }
  }

  /// Get preprocessing preview
  Future<String> getPreprocessingPreview(XFile image) async {
    try {
      final baseUrl = await _resolveBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/preprocess'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      request.headers.addAll(_defaultHeaders);

      final response = await request.send().timeout(
            const Duration(seconds: 10),
          );

      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonResponse['image_preview'] != null) {
        return jsonResponse['image_preview'];
      } else {
        throw Exception('Preprocessing failed');
      }
    } catch (e) {
      throw Exception('Preprocessing error: $e');
    }
  }
}
