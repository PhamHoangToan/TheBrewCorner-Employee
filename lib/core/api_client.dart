import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _authPrefsKey = 'employee_auth';

String _defaultBaseUrl() => 'https://thebrewcorner-be.onrender.com/api';

class ApiClient {
  ApiClient._internal(this.dio);

  final Dio dio;
  String? _token;

  static final ApiClient instance = ApiClient._internal(
    Dio(BaseOptions(baseUrl: _defaultBaseUrl(), connectTimeout: const Duration(seconds: 10))),
  ).._init();

  void _init() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token != 'dev-token') {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('$_authPrefsKey.token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('$_authPrefsKey.token');
    } else {
      await prefs.setString('$_authPrefsKey.token', token);
    }
  }

  bool get hasToken => _token != null;
}
