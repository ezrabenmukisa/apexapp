import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_identity.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/phone_verification.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_data_source.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/session_local_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._firebase, this._api, this._local);

  final FirebaseAuthDataSource _firebase;
  final AuthApiDataSource _api;
  final SessionLocalDataSource _local;

  @override
  Stream<AuthIdentity?> identityChanges() => _firebase.identityChanges();

  @override
  AuthIdentity? get currentIdentity => _firebase.currentIdentity;

  @override
  Future<Either<Failure, PhoneVerification>> sendPhoneCode(
    String phoneNumber, {
    int? resendToken,
  }) => _guard(
    () => _firebase.sendPhoneCode(phoneNumber, resendToken: resendToken),
  );

  @override
  Future<Either<Failure, Unit>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) => _guardUnit(
    () => _firebase.confirmPhoneCode(
      verificationId: verificationId,
      smsCode: smsCode,
    ),
  );

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() =>
      _guardUnit(_firebase.signInWithGoogle);

  @override
  Future<Either<Failure, Unit>> signInWithEmail({
    required String email,
    required String password,
  }) => _guardUnit(() => _firebase.signInWithEmail(email, password));

  @override
  Future<Either<Failure, Unit>> signUpWithEmail({
    required String email,
    required String password,
  }) => _guardUnit(() => _firebase.signUpWithEmail(email, password));

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) =>
      _guardUnit(() => _firebase.sendPasswordReset(email));

  @override
  Future<Either<Failure, AuthSession>> establishSession() async {
    final uid = _firebase.currentUid;
    if (uid == null) return const Left(UnauthorizedFailure());
    final result = await _guard(() async {
      final token = await _firebase.idToken();
      if (token == null) throw const UnauthorizedFailure();
      return _api.exchangeToken(token);
    });
    if (result case Left(value: NetworkFailure())) {
      // Offline on site: reopen with the last profile we saw for this uid.
      final cached = await _local.cachedUser(uid: uid);
      if (cached != null) {
        return Right(AuthSession(userId: cached.userId, profileComplete: true));
      }
    }
    return result;
  }

  @override
  Future<Either<Failure, Unit>> signOut() => _guardUnit(() async {
    await _local.clear();
    await _firebase.signOut();
  });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  Future<Either<Failure, Unit>> _guardUnit(Future<void> Function() run) =>
      _guard(() async {
        await run();
        return unit;
      });
}
