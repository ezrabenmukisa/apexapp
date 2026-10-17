// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/device/connectivity_service.dart' as _i511;
import 'package:app/core/device/device_services.dart' as _i62;
import 'package:app/core/di/register_module.dart' as _i313;
import 'package:app/core/mock/mock_api_server.dart' as _i664;
import 'package:app/core/sync/data_changes.dart' as _i833;
import 'package:app/features/account/data/repositories/settings_repository_impl.dart'
    as _i748;
import 'package:app/features/account/domain/repositories/settings_repository.dart'
    as _i576;
import 'package:app/features/account/presentation/bloc/settings_cubit.dart'
    as _i19;
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
import 'package:app/features/auth/presentation/bloc/sign_in_options_cubit.dart'
    as _i782;
import 'package:app/features/evidence/data/datasources/evidence_data_source.dart'
    as _i438;
import 'package:app/features/evidence/data/datasources/outbox_local_data_source.dart'
    as _i378;
import 'package:app/features/evidence/data/repositories/evidence_repository_impl.dart'
    as _i605;
import 'package:app/features/evidence/data/repositories/outbox_repository_impl.dart'
    as _i272;
import 'package:app/features/evidence/domain/repositories/evidence_repository.dart'
    as _i849;
import 'package:app/features/evidence/domain/usecases/evidence_usecases.dart'
    as _i31;
import 'package:app/features/evidence/presentation/bloc/evidence_cubits.dart'
    as _i283;
import 'package:app/features/milestones/data/datasources/milestones_data_source.dart'
    as _i787;
import 'package:app/features/milestones/data/repositories/milestones_repository_impl.dart'
    as _i891;
import 'package:app/features/milestones/domain/repositories/milestones_repository.dart'
    as _i537;
import 'package:app/features/milestones/domain/usecases/milestone_usecases.dart'
    as _i85;
import 'package:app/features/milestones/presentation/bloc/edit_milestone_cubit.dart'
    as _i762;
import 'package:app/features/notifications/data/datasources/notifications_data_source.dart'
    as _i584;
import 'package:app/features/notifications/data/repositories/notifications_repository_impl.dart'
    as _i655;
import 'package:app/features/notifications/domain/repositories/notifications_repository.dart'
    as _i820;
import 'package:app/features/notifications/domain/usecases/notification_usecases.dart'
    as _i838;
import 'package:app/features/notifications/presentation/bloc/inbox_cubit.dart'
    as _i178;
import 'package:app/features/projects/data/datasources/projects_data_source.dart'
    as _i82;
import 'package:app/features/projects/data/repositories/projects_repository_impl.dart'
    as _i222;
import 'package:app/features/projects/domain/repositories/projects_repository.dart'
    as _i665;
import 'package:app/features/projects/domain/usecases/project_usecases.dart'
    as _i314;
import 'package:app/features/projects/presentation/bloc/project_cubits.dart'
    as _i870;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
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
    gh.lazySingleton<_i511.ConnectivityService>(
      () => _i511.ConnectivityService(),
    );
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.lazySingleton<_i116.GoogleSignIn>(() => registerModule.googleSignIn);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i833.DataChanges>(
      () => _i833.DataChanges(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i62.PermissionsService>(
      () => _i62.SimulatedPermissionsService(),
    );
    gh.lazySingleton<_i62.PushTokenProvider>(
      () => _i62.SimulatedPushTokenProvider(),
    );
    gh.lazySingleton<_i62.LocationService>(
      () => _i62.SimulatedLocationService(),
    );
    gh.lazySingleton<_i62.ReceiptPicker>(() => _i62.SimulatedReceiptPicker());
    gh.lazySingleton<_i62.GeocodingService>(
      () => _i62.SimulatedGeocodingService(),
    );
    gh.lazySingleton<_i818.SessionLocalDataSource>(
      () => _i818.SessionLocalDataSource(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i378.OutboxLocalDataSource>(
      () => _i378.OutboxLocalDataSource(gh<_i558.FlutterSecureStorage>()),
    );
    gh.factory<_i19.PermissionsCubit>(
      () => _i19.PermissionsCubit(gh<_i62.PermissionsService>()),
    );
    gh.lazySingleton<_i199.MockUserStore>(
      () => _i199.MockUserStore(
        gh<_i59.FirebaseAuth>(),
        gh<_i460.SharedPreferences>(),
      ),
      registerFor: {_mock},
    );
    gh.factory<_i283.EvidenceDraftCubit>(
      () => _i283.EvidenceDraftCubit(gh<_i62.ReceiptPicker>()),
    );
    gh.lazySingleton<_i491.AuthApiDataSource>(
      () => _i491.AuthApiDataSourceMock(gh<_i199.MockUserStore>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i576.SettingsRepository>(
      () => _i748.SettingsRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i607.ProfileApiDataSource>(
      () => _i607.ProfileApiDataSourceMock(gh<_i199.MockUserStore>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i438.EvidenceDataSource>(
      () => _i438.EvidenceDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.factory<_i19.SettingsCubit>(
      () => _i19.SettingsCubit(gh<_i576.SettingsRepository>()),
    );
    gh.lazySingleton<_i584.NotificationsDataSource>(
      () => _i584.NotificationsDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.lazySingleton<_i82.ProjectsDataSource>(
      () => _i82.ProjectsDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.lazySingleton<_i787.MilestonesDataSource>(
      () => _i787.MilestonesDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.lazySingleton<_i510.FirebaseAuthDataSource>(
      () => _i510.FirebaseAuthDataSource(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i664.MockApiServer>(
      () => _i664.MockApiServer(
        gh<_i199.MockUserStore>(),
        gh<_i460.SharedPreferences>(),
      ),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i62.CaptureService>(
      () => _i62.SimulatedCaptureService(gh<_i62.LocationService>()),
    );
    gh.lazySingleton<_i584.NotificationsDataSource>(
      () => _i584.NotificationsDataSourceMock(gh<_i664.MockApiServer>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i438.EvidenceDataSource>(
      () => _i438.EvidenceDataSourceMock(gh<_i664.MockApiServer>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i820.NotificationsRepository>(
      () => _i655.NotificationsRepositoryImpl(
        gh<_i584.NotificationsDataSource>(),
        gh<_i62.PushTokenProvider>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.lazySingleton<_i849.EvidenceRepository>(
      () => _i605.EvidenceRepositoryImpl(
        gh<_i438.EvidenceDataSource>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.lazySingleton<_i82.ProjectsDataSource>(
      () => _i82.ProjectsDataSourceMock(gh<_i664.MockApiServer>()),
      registerFor: {_mock},
    );
    gh.lazySingleton<_i849.OutboxRepository>(
      () => _i272.OutboxRepositoryImpl(
        gh<_i378.OutboxLocalDataSource>(),
        gh<_i438.EvidenceDataSource>(),
        gh<_i510.FirebaseAuthDataSource>(),
        gh<_i511.ConnectivityService>(),
        gh<_i576.SettingsRepository>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.lazySingleton<_i607.ProfileApiDataSource>(
      () => _i607.ProfileApiDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.factory<_i283.CaptureCubit>(
      () => _i283.CaptureCubit(
        gh<_i62.CaptureService>(),
        gh<_i62.LocationService>(),
      ),
    );
    gh.lazySingleton<_i491.AuthApiDataSource>(
      () => _i491.AuthApiDataSourceRemote(gh<_i361.Dio>()),
      registerFor: {_remote},
    );
    gh.factory<_i31.ReviewEvidence>(
      () => _i31.ReviewEvidence(gh<_i849.EvidenceRepository>()),
    );
    gh.factory<_i31.EnqueueEvidence>(
      () => _i31.EnqueueEvidence(gh<_i849.OutboxRepository>()),
    );
    gh.lazySingleton<_i631.ProfileRepository>(
      () => _i822.ProfileRepositoryImpl(
        gh<_i607.ProfileApiDataSource>(),
        gh<_i818.SessionLocalDataSource>(),
        gh<_i510.FirebaseAuthDataSource>(),
      ),
    );
    gh.lazySingleton<_i787.MilestonesDataSource>(
      () => _i787.MilestonesDataSourceMock(gh<_i664.MockApiServer>()),
      registerFor: {_mock},
    );
    gh.factory<_i838.ListNotifications>(
      () => _i838.ListNotifications(gh<_i820.NotificationsRepository>()),
    );
    gh.factory<_i838.MarkNotificationRead>(
      () => _i838.MarkNotificationRead(gh<_i820.NotificationsRepository>()),
    );
    gh.factory<_i838.RegisterPushToken>(
      () => _i838.RegisterPushToken(gh<_i820.NotificationsRepository>()),
    );
    gh.lazySingleton<_i665.ProjectsRepository>(
      () => _i222.ProjectsRepositoryImpl(
        gh<_i82.ProjectsDataSource>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.lazySingleton<_i537.MilestonesRepository>(
      () => _i891.MilestonesRepositoryImpl(
        gh<_i787.MilestonesDataSource>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.factory<_i314.CreateProject>(
      () => _i314.CreateProject(gh<_i665.ProjectsRepository>()),
    );
    gh.factory<_i314.UpdateProject>(
      () => _i314.UpdateProject(gh<_i665.ProjectsRepository>()),
    );
    gh.factory<_i314.InviteMember>(
      () => _i314.InviteMember(gh<_i665.ProjectsRepository>()),
    );
    gh.factory<_i314.RemoveMember>(
      () => _i314.RemoveMember(gh<_i665.ProjectsRepository>()),
    );
    gh.factory<_i314.ListProjectMembers>(
      () => _i314.ListProjectMembers(gh<_i665.ProjectsRepository>()),
    );
    gh.factory<_i870.ProjectFormCubit>(
      () => _i870.ProjectFormCubit(
        gh<_i314.CreateProject>(),
        gh<_i314.UpdateProject>(),
        gh<_i62.LocationService>(),
        gh<_i62.GeocodingService>(),
      ),
    );
    gh.lazySingleton<_i765.AuthRepository>(
      () => _i39.AuthRepositoryImpl(
        gh<_i510.FirebaseAuthDataSource>(),
        gh<_i491.AuthApiDataSource>(),
        gh<_i818.SessionLocalDataSource>(),
      ),
    );
    gh.factoryParam<_i870.TeamCubit, String?, dynamic>(
      (projectId, _) => _i870.TeamCubit(
        projectId,
        gh<_i314.ListProjectMembers>(),
        gh<_i314.InviteMember>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.factory<_i1065.GetProfile>(
      () => _i1065.GetProfile(gh<_i631.ProfileRepository>()),
    );
    gh.factory<_i1065.UpdateProfile>(
      () => _i1065.UpdateProfile(gh<_i631.ProfileRepository>()),
    );
    gh.factory<_i314.GetOwnerDashboard>(
      () => _i314.GetOwnerDashboard(
        gh<_i665.ProjectsRepository>(),
        gh<_i537.MilestonesRepository>(),
      ),
    );
    gh.factory<_i314.GetProjectOverview>(
      () => _i314.GetProjectOverview(
        gh<_i665.ProjectsRepository>(),
        gh<_i537.MilestonesRepository>(),
      ),
    );
    gh.factory<_i178.InboxCubit>(
      () => _i178.InboxCubit(
        gh<_i838.ListNotifications>(),
        gh<_i838.MarkNotificationRead>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.factory<_i283.OutboxCubit>(
      () => _i283.OutboxCubit(
        gh<_i849.OutboxRepository>(),
        gh<_i31.EnqueueEvidence>(),
        gh<_i511.ConnectivityService>(),
      ),
    );
    gh.factory<_i876.CompleteProfileCubit>(
      () => _i876.CompleteProfileCubit(gh<_i1065.UpdateProfile>()),
    );
    gh.factory<_i870.DashboardCubit>(
      () => _i870.DashboardCubit(
        gh<_i314.GetOwnerDashboard>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.factory<_i85.ListMilestones>(
      () => _i85.ListMilestones(gh<_i537.MilestonesRepository>()),
    );
    gh.factory<_i85.GetMilestone>(
      () => _i85.GetMilestone(gh<_i537.MilestonesRepository>()),
    );
    gh.factory<_i85.CreateMilestone>(
      () => _i85.CreateMilestone(gh<_i537.MilestonesRepository>()),
    );
    gh.factory<_i85.UpdateMilestone>(
      () => _i85.UpdateMilestone(gh<_i537.MilestonesRepository>()),
    );
    gh.factory<_i85.ApplyHouseTemplate>(
      () => _i85.ApplyHouseTemplate(gh<_i537.MilestonesRepository>()),
    );
    gh.factory<_i31.GetReviewContext>(
      () => _i31.GetReviewContext(
        gh<_i314.GetProjectOverview>(),
        gh<_i849.EvidenceRepository>(),
      ),
    );
    gh.factoryParam<_i870.ProjectOverviewCubit, String?, dynamic>(
      (projectId, _) => _i870.ProjectOverviewCubit(
        projectId,
        gh<_i314.GetProjectOverview>(),
        gh<_i314.UpdateProject>(),
        gh<_i314.RemoveMember>(),
        gh<_i85.ApplyHouseTemplate>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.factory<_i31.GetSiteAssignment>(
      () => _i31.GetSiteAssignment(
        gh<_i665.ProjectsRepository>(),
        gh<_i314.GetProjectOverview>(),
        gh<_i849.EvidenceRepository>(),
      ),
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
    gh.factory<_i72.SignInWithGoogle>(
      () => _i72.SignInWithGoogle(gh<_i765.AuthRepository>()),
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
    gh.factory<_i283.SiteCubit>(
      () => _i283.SiteCubit(
        gh<_i31.GetSiteAssignment>(),
        gh<_i62.LocationService>(),
        gh<_i833.DataChanges>(),
      ),
    );
    gh.factory<_i686.EmailAuthCubit>(
      () => _i686.EmailAuthCubit(
        gh<_i72.SignInWithEmail>(),
        gh<_i72.SignUpWithEmail>(),
        gh<_i72.SendPasswordReset>(),
      ),
    );
    gh.factory<_i782.SignInOptionsCubit>(
      () => _i782.SignInOptionsCubit(gh<_i72.SignInWithGoogle>()),
    );
    gh.lazySingleton<_i200.AuthBloc>(
      () => _i200.AuthBloc(
        gh<_i72.WatchAuthIdentity>(),
        gh<_i72.EstablishSession>(),
        gh<_i1065.GetProfile>(),
        gh<_i72.SignOut>(),
      ),
    );
    gh.factory<_i762.EditMilestoneCubit>(
      () => _i762.EditMilestoneCubit(
        gh<_i85.CreateMilestone>(),
        gh<_i85.UpdateMilestone>(),
      ),
    );
    gh.factoryParam<_i283.ReviewEvidenceCubit, String?, dynamic>(
      (ids, _) => _i283.ReviewEvidenceCubit(
        ids,
        gh<_i31.GetReviewContext>(),
        gh<_i31.ReviewEvidence>(),
        gh<_i833.DataChanges>(),
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
