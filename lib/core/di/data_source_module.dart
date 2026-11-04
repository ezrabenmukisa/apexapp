import 'package:injectable/injectable.dart';

import '../../features/evidence/data/datasources/evidence_data_source.dart';
import '../../features/milestones/data/datasources/milestones_data_source.dart';
import '../../features/notifications/data/datasources/notifications_data_source.dart';
import '../../features/projects/data/datasources/projects_data_source.dart';
import '../config/app_config.dart';

/// Chooses, per feature, between the real API and the in-app mock server
/// using the `LIVE_*` switches in `.env`. Auth and profile are always live
/// and are bound directly on their remote data sources.
@module
abstract class DataSourceModule {
  @lazySingleton
  ProjectsDataSource projects(
    ProjectsDataSourceRemote remote,
    ProjectsDataSourceMock mock,
  ) => AppConfig.live.projects ? remote : mock;

  @lazySingleton
  MilestonesDataSource milestones(
    MilestonesDataSourceRemote remote,
    MilestonesDataSourceMock mock,
  ) => AppConfig.live.milestones ? remote : mock;

  @lazySingleton
  EvidenceDataSource evidence(
    EvidenceDataSourceRemote remote,
    EvidenceDataSourceMock mock,
  ) => AppConfig.live.evidence ? remote : mock;

  @lazySingleton
  NotificationsDataSource notifications(
    NotificationsDataSourceRemote remote,
    NotificationsDataSourceMock mock,
  ) => AppConfig.live.notifications ? remote : mock;
}
