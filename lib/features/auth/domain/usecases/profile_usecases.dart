import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../entities/profile_update.dart';
import '../repositories/profile_repository.dart';

@injectable
class GetProfile implements UseCase<AppUser, NoParams> {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) =>
      _repository.getProfile();
}

@injectable
class UpdateProfile implements UseCase<AppUser, ProfileUpdate> {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(ProfileUpdate params) =>
      _repository.updateProfile(params);
}
