import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/auth_session.dart';
import '../models/auth_session_model.dart';
import 'mock_user_store.dart';

/// Backend half of authentication: `POST /auth/firebase`.
abstract interface class AuthApiDataSource {
  Future<AuthSession> exchangeToken(String idToken);
}

@remote
@LazySingleton(as: AuthApiDataSource)
class AuthApiDataSourceRemote implements AuthApiDataSource {
  const AuthApiDataSourceRemote(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> exchangeToken(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authFirebase,
      data: {'id_token': idToken},
    );
    return AuthSessionModel.fromJson(response.data!);
  }
}

@mock
@LazySingleton(as: AuthApiDataSource)
class AuthApiDataSourceMock implements AuthApiDataSource {
  const AuthApiDataSourceMock(this._store);

  final MockUserStore _store;

  @override
  Future<AuthSession> exchangeToken(String idToken) async {
    await Future<void>.delayed(AppConfig.mockLatency);
    final profile = _store.currentProfile();
    return AuthSession(
      userId: _store.currentUserId(),
      profileComplete: profile != null,
    );
  }
}
