import 'package:fpdart/fpdart.dart';

import 'error_mapper.dart';
import 'failures.dart';

/// Runs data-source calls and converts anything thrown into a [Failure].
mixin RepositoryGuard {
  Future<Either<Failure, T>> guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e, st) {
      return Left(mapErrorToFailure(e, st));
    }
  }
}
