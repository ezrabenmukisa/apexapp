import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/profile_api_data_source.dart';
import '../datasources/role_local_data_source.dart';
import '../datasources/session_local_data_source.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(
    this._api,
    this._local,
    this._roles,
    this._firebase,
  );

  final ProfileApiDataSource _api;
  final SessionLocalDataSource _local;
  final RoleLocalDataSource _roles;
  final FirebaseAuthDataSource _firebase;

  @override
  Future<Either<Failure, AppUser>> getProfile() async {
    final uid = _firebase.currentUid;
    if (uid == null) return const Left(UnauthorizedFailure());
    try {
      final user = await _withRole(uid, await _api.getMe());
      await _local.cacheUser(user, uid: uid);
      return Right(user);
    } catch (e, st) {
      final failure = mapErrorToFailure(e, st);
      if (failure is NetworkFailure) {
        final cached = await _local.cachedUser(uid: uid);
        if (cached != null) return Right(await _withRole(uid, cached));
      }
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, AppUser>> updateProfile(ProfileUpdate update) async {
    final uid = _firebase.currentUid;
    if (uid == null) return const Left(UnauthorizedFailure());
    try {
      final updated = await _api.updateMe(update);
      if (update.userRole case final role?) await _roles.write(uid, role);
      final user = await _withRole(uid, updated);
      await _local.cacheUser(user, uid: uid);
      return Right(user);
    } catch (e, st) {
      return Left(mapErrorToFailure(e, st));
    }
  }

  /// The API doesn't return `user_role` yet: use the one remembered on this
  /// phone. If a future API version returns it, that wins and is remembered.
  Future<AppUser> _withRole(String uid, AppUser user) async {
    final fromApi = user.userRole;
    if (fromApi != null) {
      await _roles.write(uid, fromApi);
      return user;
    }
    return user.copyWith(userRole: _roles.read(uid));
  }
}
