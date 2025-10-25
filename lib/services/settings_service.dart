import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _serverUrlKey = 'server_url';
  static const String _deviceIdKey = 'device_id';
  static const String _defaultServerUrl = 'http://192.168.0.10:8080';
  static const String _defaultDeviceId = 'mobile_01';

  /// Get server URL from settings
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
  }

  /// Set server URL in settings
  static Future<bool> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_serverUrlKey, url);
  }

  /// Get device ID from settings
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey) ?? _defaultDeviceId;
  }

  /// Set device ID in settings
  static Future<bool> setDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_deviceIdKey, deviceId);
  }

  /// Reset all settings to default
  static Future<bool> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverUrlKey);
    await prefs.remove(_deviceIdKey);
    return true;
  }
}
