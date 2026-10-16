import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_update.dart';
import '../models/app_user_model.dart';
import 'mock_user_store.dart';

/// `GET` and `PATCH /users/me`. Identity comes from the bearer token.
abstract interface class ProfileApiDataSource {
  Future<AppUser> getMe();

  Future<AppUser> updateMe(ProfileUpdate update);
}

@remote
@LazySingleton(as: ProfileApiDataSource)
class ProfileApiDataSourceRemote implements ProfileApiDataSource {
  const ProfileApiDataSourceRemote(this._dio);

  final Dio _dio;

  @override
  Future<AppUser> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return AppUserModel.fromJson(response.data!);
  }

  @override
  Future<AppUser> updateMe(ProfileUpdate update) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: profileUpdateToJson(update),
    );
    return AppUserModel.fromJson(response.data!);
  }
}

@mock
@LazySingleton(as: ProfileApiDataSource)
class ProfileApiDataSourceMock implements ProfileApiDataSource {
  const ProfileApiDataSourceMock(this._store);

  final MockUserStore _store;

  @override
  Future<AppUser> getMe() async {
    await Future<void>.delayed(AppConfig.mockLatency);
    final json = _store.currentProfile();
    if (json == null) {
      throw const ServerException('Profile not found', statusCode: 404);
    }
    return AppUserModel.fromJson(json);
  }

  @override
  Future<AppUser> updateMe(ProfileUpdate update) async {
    await Future<void>.delayed(AppConfig.mockLatency);
    final json = {
      'user_id': _store.currentUserId(),
      ...?_store.currentProfile(),
      ...profileUpdateToJson(update),
    };
    for (final field in const ['first_name', 'last_name', 'contact_email']) {
      if ((json[field] as String?)?.trim().isEmpty ?? true) {
        throw ServerException('$field is required', statusCode: 422);
      }
    }
    await _store.saveProfile(json);
    return AppUserModel.fromJson(json);
  }
}
