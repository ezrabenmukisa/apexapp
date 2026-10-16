import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../entities/profile_update.dart';

abstract interface class ProfileRepository {
  /// `GET /users/me`. Falls back to the cached profile when offline.
  Future<Either<Failure, AppUser>> getProfile();

  /// `PATCH /users/me`.
  Future<Either<Failure, AppUser>> updateProfile(ProfileUpdate update);
}
