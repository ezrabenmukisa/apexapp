import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_update.dart';
import '../models/app_user_model.dart';

/// `GET` and `PATCH /users/me`. Identity comes from the bearer token.
abstract interface class ProfileApiDataSource {
  Future<AppUser> getMe();

  Future<AppUser> updateMe(ProfileUpdate update);
}

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
