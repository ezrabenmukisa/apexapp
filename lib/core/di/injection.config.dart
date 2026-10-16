// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/di/register_module.dart' as _i313;
import 'package:app/features/auth/data/datasources/auth_api_data_source.dart'
    as _i491;
import 'package:app/features/auth/data/datasources/firebase_auth_data_source.dart'
    as _i510;
import 'package:app/features/auth/data/datasources/mock_user_store.dart'
    as _i199;
import 'package:app/features/auth/data/datasources/profile_api_data_source.dart'
    as _i607;
import 'package:app/features/auth/data/datasources/session_local_data_source.dart'
    as _i818;
import 'package:app/features/auth/data/repositories/auth_repository_impl.dart'
    as _i39;
import 'package:app/features/auth/data/repositories/profile_repository_impl.dart'
    as _i822;
import 'package:app/features/auth/domain/repositories/auth_repository.dart'
    as _i765;
import 'package:app/features/auth/domain/repositories/profile_repository.dart'
    as _i631;
import 'package:app/features/auth/domain/usecases/auth_usecases.dart' as _i72;
import 'package:app/features/auth/domain/usecases/profile_usecases.dart'
    as _i1065;
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart' as _i200;
import 'package:app/features/auth/presentation/bloc/complete_profile_cubit.dart'
    as _i876;
import 'package:app/features/auth/presentation/bloc/email_auth_cubit.dart'
    as _i686;
import 'package:app/features/auth/presentation/bloc/phone_auth_cubit.dart'
    as _i459;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

const String _mock = 'mock';
const String _remote = 'remote';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i974.Logger>(() => registerModule.logger);
    gh.lazySingleton<_i818.SessionLocalDataSource>(
      () => _i818.SessionLocalDataSource(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i199.MockUserStore>(
      () => _i199.MockUserStore(
        gh<_i59.FirebaseAuth>(),
        gh<_i460.SharedPreferences>(),
      ),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i491.AuthApiDataSource>(
      () => _i491.AuthApiDataSourceMock(gh<_i199.MockUserStore>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i607.ProfileApiDataSource>(
      () => _i607.ProfileApiDataSourceMock(gh<_i199.MockUserStore>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(gh<_i59.FirebaseAuth>(), gh<_i974.Logger>()),
    );
    gh.lazySingleton<_i510.FirebaseAuthDataSource>(
      () => _i510.FirebaseAuthDataSource(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i607.ProfileApiDataSource>(
      () => _i607.ProfileApiDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.lazySingleton<_i491.AuthApiDataSource>(
      () => _i491.AuthApiDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.lazySingleton<_i631.ProfileRepository>(
      () => _i822.ProfileRepositoryImpl(
        gh<_i607.ProfileApiDataSource>(),
        gh<_i818.SessionLocalDataSource>(),
        gh<_i510.FirebaseAuthDataSource>(),
      ),
    );
    gh.lazySingleton<_i765.AuthRepository>(
      () => _i39.AuthRepositoryImpl(
        gh<_i510.FirebaseAuthDataSource>(),
        gh<_i491.AuthApiDataSource>(),
        gh<_i818.SessionLocalDataSource>(),
      ),
    );
    gh.factory<_i1065.GetProfile>(
      () => _i1065.GetProfile(gh<_i631.ProfileRepository>()),
    );
    gh.factory<_i1065.UpdateProfile>(
      () => _i1065.UpdateProfile(gh<_i631.ProfileRepository>()),
    );
    gh.factory<_i876.CompleteProfileCubit>(
      () => _i876.CompleteProfileCubit(gh<_i1065.UpdateProfile>()),
    );
    gh.factory<_i72.WatchAuthIdentity>(
      () => _i72.WatchAuthIdentity(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.SendPhoneCode>(
      () => _i72.SendPhoneCode(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.ConfirmPhoneCode>(
      () => _i72.ConfirmPhoneCode(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.SignInWithEmail>(
      () => _i72.SignInWithEmail(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.SignUpWithEmail>(
      () => _i72.SignUpWithEmail(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.SendPasswordReset>(
      () => _i72.SendPasswordReset(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.EstablishSession>(
      () => _i72.EstablishSession(gh<_i765.AuthRepository>()),
    );
    gh.factory<_i72.SignOut>(() => _i72.SignOut(gh<_i765.AuthRepository>()));
    gh.factory<_i686.EmailAuthCubit>(
      () => _i686.EmailAuthCubit(
        gh<_i72.SignInWithEmail>(),
        gh<_i72.SignUpWithEmail>(),
        gh<_i72.SendPasswordReset>(),
      ),
    );
    gh.lazySingleton<_i200.AuthBloc>(
      () => _i200.AuthBloc(
        gh<_i72.WatchAuthIdentity>(),
        gh<_i72.EstablishSession>(),
        gh<_i1065.GetProfile>(),
        gh<_i72.SignOut>(),
      ),
    );
    gh.factory<_i459.PhoneAuthCubit>(
      () => _i459.PhoneAuthCubit(
        gh<_i72.SendPhoneCode>(),
        gh<_i72.ConfirmPhoneCode>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i313.RegisterModule {}
