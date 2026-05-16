import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyEmployeeId = 'employee_id';
  static const _keyEmployeeRole = 'employee_role';
  static const _keySessionKey = 'ai_session_key';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> saveEmployeeId(String id) =>
      _storage.write(key: _keyEmployeeId, value: id);

  static Future<String?> getEmployeeId() => _storage.read(key: _keyEmployeeId);

  static Future<void> saveRole(String role) =>
      _storage.write(key: _keyEmployeeRole, value: role);

  static Future<String?> getRole() => _storage.read(key: _keyEmployeeRole);

  static Future<void> saveAiSessionKey(String key) =>
      _storage.write(key: _keySessionKey, value: key);

  static Future<String?> getAiSessionKey() => _storage.read(key: _keySessionKey);

  static Future<void> clearAll() => _storage.deleteAll();
}
