import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echofit/services/settings_service.dart';

void main() {
  group('SettingsService Tests', () {
    late SettingsService settingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
    });

    test('saveCredentials should store values in SharedPreferences', () async {
      await settingsService.saveCredentials('https://test.com', 'user', 'pass');
      
      final creds = await settingsService.getCredentials();
      expect(creds['url'], 'https://test.com');
      expect(creds['username'], 'user');
      expect(creds['password'], 'pass');
    });

    test('hasCredentials should return true when all values are set', () async {
      expect(await settingsService.hasCredentials(), false);

      await settingsService.saveCredentials('url', 'user', 'pass');
      expect(await settingsService.hasCredentials(), true);
    });

    test('hasCredentials should return false if any value is missing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nextcloud_url', 'url');
      // username and password missing
      
      expect(await settingsService.hasCredentials(), false);
    });
  });
}
