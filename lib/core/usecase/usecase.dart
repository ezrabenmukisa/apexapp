import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// A single application action. Takes [Params], returns a [Failure] or [T].
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Parameter type for use cases that take no input.
final class NoParams {
  const NoParams();
}
