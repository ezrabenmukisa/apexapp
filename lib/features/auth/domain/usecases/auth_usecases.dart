import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_identity.dart';
import '../entities/auth_session.dart';
import '../entities/phone_verification.dart';
import '../repositories/auth_repository.dart';

@injectable
class WatchAuthIdentity {
  const WatchAuthIdentity(this._repository);

  final AuthRepository _repository;

  Stream<AuthIdentity?> call() => _repository.identityChanges();
}

typedef SendPhoneCodeParams = ({String phoneNumber, int? resendToken});

@injectable
class SendPhoneCode implements UseCase<PhoneVerification, SendPhoneCodeParams> {
  const SendPhoneCode(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, PhoneVerification>> call(SendPhoneCodeParams params) =>
      _repository.sendPhoneCode(
        params.phoneNumber,
        resendToken: params.resendToken,
      );
}

typedef ConfirmPhoneCodeParams = ({String verificationId, String smsCode});

@injectable
class ConfirmPhoneCode implements UseCase<Unit, ConfirmPhoneCodeParams> {
  const ConfirmPhoneCode(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ConfirmPhoneCodeParams params) =>
      _repository.confirmPhoneCode(
        verificationId: params.verificationId,
        smsCode: params.smsCode,
      );
}

typedef EmailCredentials = ({String email, String password});

@injectable
class SignInWithEmail implements UseCase<Unit, EmailCredentials> {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EmailCredentials params) => _repository
      .signInWithEmail(email: params.email, password: params.password);
}

@injectable
class SignUpWithEmail implements UseCase<Unit, EmailCredentials> {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EmailCredentials params) => _repository
      .signUpWithEmail(email: params.email, password: params.password);
}

@injectable
class SendPasswordReset implements UseCase<Unit, String> {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repository.sendPasswordReset(email);
}

@injectable
class EstablishSession implements UseCase<AuthSession, NoParams> {
  const EstablishSession(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSession>> call(NoParams params) =>
      _repository.establishSession();
}

@injectable
class SignOut implements UseCase<Unit, NoParams> {
  const SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}
