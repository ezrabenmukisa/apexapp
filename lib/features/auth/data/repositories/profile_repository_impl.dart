import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/profile_api_data_source.dart';
import '../datasources/session_local_data_source.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._api, this._local, this._firebase);

  final ProfileApiDataSource _api;
  final SessionLocalDataSource _local;
  final FirebaseAuthDataSource _firebase;

  @override
  Future<Either<Failure, AppUser>> getProfile() async {
    final uid = _firebase.currentUid;
    if (uid == null) return const Left(UnauthorizedFailure());
    try {
      final fetched = await _api.getMe();
      // Until the API returns user_role, keep the one chosen on this phone.
      final cached = await _local.cachedUser(uid: uid);
      final user = fetched.userRole == null
          ? fetched.copyWith(userRole: cached?.userRole)
          : fetched;
      await _local.cacheUser(user, uid: uid);
      return Right(user);
    } catch (e, st) {
      final failure = mapErrorToFailure(e, st);
      if (failure is NetworkFailure) {
        final cached = await _local.cachedUser(uid: uid);
        if (cached != null) return Right(cached);
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
      final user = updated.userRole == null
          ? updated.copyWith(userRole: update.userRole)
          : updated;
      await _local.cacheUser(user, uid: uid);
      return Right(user);
    } catch (e, st) {
      return Left(mapErrorToFailure(e, st));
    }
  }
}
