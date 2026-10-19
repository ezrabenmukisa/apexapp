import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/auth_session.dart';
import '../models/auth_session_model.dart';

/// Backend half of authentication: `POST /auth/firebase`.
abstract interface class AuthApiDataSource {
  Future<AuthSession> exchangeToken(String idToken);
}

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
