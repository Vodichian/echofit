import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyServerUrl = 'nextcloud_url';
  static const _keyUsername = 'nextcloud_username';
  static const _keyPassword = 'nextcloud_password';

  Future<void> saveCredentials(String url, String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
    await prefs.setString(_keyUsername, user);
    await prefs.setString(_keyPassword, pass);
  }

  Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString(_keyServerUrl),
      'username': prefs.getString(_keyUsername),
      'password': prefs.getString(_keyPassword),
    };
  }

  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds['url'] != null && creds['username'] != null && creds['password'] != null;
  }
}
