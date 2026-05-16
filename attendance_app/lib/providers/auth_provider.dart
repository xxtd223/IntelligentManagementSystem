import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/storage/local_storage.dart';
import '../models/employee.dart';

class AuthState {
  final Employee? employee;
  final bool isLoading;
  final String? error;

  const AuthState({this.employee, this.isLoading = false, this.error});

  bool get isLoggedIn => employee != null;
  bool get isAdmin => employee?.isAdmin ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String employeeNo, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final resp = await DioClient.post(ApiConstants.login, data: {
        'employeeNo': employeeNo,
        'password': password,
      });
      final data = resp['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final employee = Employee.fromJson(data['employee'] as Map<String, dynamic>);

      await LocalStorage.saveToken(token);
      await LocalStorage.saveEmployeeId(employee.id.toString());
      await LocalStorage.saveRole(employee.role);

      state = AuthState(employee: employee);
    } catch (e) {
      state = AuthState(error: _parseError(e));
    }
  }

  Future<void> restoreSession() async {
    final token = await LocalStorage.getToken();
    if (token == null) return;

    try {
      final resp = await DioClient.get(ApiConstants.me);
      final employee = Employee.fromJson(resp['data'] as Map<String, dynamic>);
      state = AuthState(employee: employee);
    } catch (_) {
      await LocalStorage.clearAll();
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearAll();
    state = const AuthState();
  }

  String _parseError(Object e) {
    if (e.toString().contains('1001')) return '账号或密码错误';
    if (e.toString().contains('1002')) return '账号已停用，请联系管理员';
    return '登录失败，请检查网络连接';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
