import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';

const _userPrefsKey = 'employee_auth.user';

class AuthState {
  const AuthState({this.user, this.loading = false, this.error, this.restoring = true});

  final AppUser? user;
  final bool loading;
  final String? error;
  final bool restoring;

  bool get isLoggedIn => user != null;

  AuthState copyWith({AppUser? user, bool? loading, String? error, bool? restoring}) => AuthState(
        user: user ?? this.user,
        loading: loading ?? this.loading,
        error: error,
        restoring: restoring ?? this.restoring,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    await ApiClient.instance.loadToken();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userPrefsKey);
    if (raw != null && ApiClient.instance.hasToken) {
      try {
        final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        state = state.copyWith(user: user, restoring: false);
        return;
      } catch (_) {
        // fall through to logged-out state
      }
    }
    state = state.copyWith(restoring: false);
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final loginRes = await ApiClient.instance.dio.post('/auth/login', data: {
        'code': identifier,
        'username': identifier,
        'password': password,
      });
      final token = loginRes.data['token'] as String;
      final loggedInId = loginRes.data['user']['id'] as String;

      await ApiClient.instance.setToken(token);

      final profileRes = await ApiClient.instance.dio.get('/users/$loggedInId');
      final user = AppUser.fromJson(profileRes.data as Map<String, dynamic>);

      await _persist(user);
      state = state.copyWith(user: user, loading: false);
      return true;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Sai tên đăng nhập hoặc mật khẩu');
      return false;
    }
  }

  Future<void> _persist(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPrefsKey, jsonEncode({
      'id': user.id,
      'code': user.code,
      'name': user.name,
      'role': user.role,
      'paidLeaveDaysLeft': user.paidLeaveDaysLeft,
      'mustChangePassword': user.mustChangePassword,
    }));
  }

  /// Returns null on success, or an error message to show the user.
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final user = state.user;
    if (user == null) return 'Phiên đăng nhập đã hết hạn';
    try {
      await ApiClient.instance.dio.patch('/users/${user.id}/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      final updated = user.copyWith(mustChangePassword: false);
      await _persist(updated);
      state = state.copyWith(user: updated);
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Đổi mật khẩu thất bại';
    } catch (_) {
      return 'Đổi mật khẩu thất bại';
    }
  }

  Future<void> refreshProfile() async {
    final id = state.user?.id;
    if (id == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/users/$id');
      state = state.copyWith(user: AppUser.fromJson(res.data as Map<String, dynamic>));
    } catch (_) {
      // keep stale profile on failure; UI already shows last known values
    }
  }

  Future<void> logout() async {
    await ApiClient.instance.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPrefsKey);
    state = const AuthState(restoring: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
