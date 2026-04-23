import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/upload_item.dart';

class StorageService {
  static const String _uploadHistoryKey = 'upload_history';
  static const String _apiUrlKey = 'api_url';

  late SharedPreferences _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get semua history uploads
  Future<List<UploadItem>> getUploadHistory() async {
    try {
      final jsonString = _prefs.getString(_uploadHistoryKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => UploadItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  /// Add new upload ke history
  Future<void> addUploadToHistory(UploadItem item) async {
    try {
      final history = await getUploadHistory();
      history.insert(0, item); // Add ke awal (newest first)

      // Limit ke 100 items
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }

      final jsonString = jsonEncode(
        history.map((item) => item.toJson()).toList(),
      );
      await _prefs.setString(_uploadHistoryKey, jsonString);
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  /// Update existing upload item
  Future<void> updateUploadItem(UploadItem item) async {
    try {
      final history = await getUploadHistory();
      final index = history.indexWhere((h) => h.id == item.id);

      if (index != -1) {
        history[index] = item;
        final jsonString = jsonEncode(
          history.map((item) => item.toJson()).toList(),
        );
        await _prefs.setString(_uploadHistoryKey, jsonString);
      }
    } catch (e) {
      print('Error updating item: $e');
    }
  }

  /// Delete upload item
  Future<void> deleteUploadItem(String id) async {
    try {
      final history = await getUploadHistory();
      history.removeWhere((item) => item.id == id);

      final jsonString = jsonEncode(
        history.map((item) => item.toJson()).toList(),
      );
      await _prefs.setString(_uploadHistoryKey, jsonString);
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    try {
      await _prefs.remove(_uploadHistoryKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  /// Get saved API URL
  Future<String> getApiUrl() async {
    return _prefs.getString(_apiUrlKey) ?? 'http://localhost:5000';
  }

  /// Save API URL
  Future<void> setApiUrl(String url) async {
    await _prefs.setString(_apiUrlKey, url);
  }

  /// Get upload item by ID
  Future<UploadItem?> getUploadItemById(String id) async {
    try {
      final history = await getUploadHistory();
      return history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get upload statistics
  Future<Map<String, int>> getUploadStats() async {
    try {
      final history = await getUploadHistory();
      final total = history.length;
      final successful =
          history.where((item) => item.recognizedText != null).length;
      final failed = history.where((item) => item.errorMessage != null).length;

      return {
        'total': total,
        'successful': successful,
        'failed': failed,
      };
    } catch (e) {
      return {'total': 0, 'successful': 0, 'failed': 0};
    }
  }
}
