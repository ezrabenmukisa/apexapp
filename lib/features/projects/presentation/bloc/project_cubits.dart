import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/device/device_services.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/data_changes.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../milestones/domain/usecases/milestone_usecases.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_overview.dart';
import '../../domain/usecases/project_usecases.dart';

/// Owner home and the Review tab (shared at shell level for the badge).
@injectable
class DashboardCubit extends LoadCubit<OwnerDashboard> {
  DashboardCubit(this._get, DataChanges changes)
    : super(changes, {
        DataTopic.projects,
        DataTopic.milestones,
        DataTopic.evidence,
      });

  final GetOwnerDashboard _get;

  @override
  Future<Either<Failure, OwnerDashboard>> fetch() => _get(const NoParams());
}

/// Project detail, settings and the milestone plan.
@injectable
class ProjectOverviewCubit extends LoadCubit<ProjectOverview> {
  ProjectOverviewCubit(
    @factoryParam this.projectId,
    this._get,
    this._update,
    this._remove,
    this._template,
    DataChanges changes,
  ) : super(changes, {
        DataTopic.projects,
        DataTopic.milestones,
        DataTopic.members,
        DataTopic.evidence,
      });

  final String? projectId;
  final GetProjectOverview _get;
  final UpdateProject _update;
  final RemoveMember _remove;
  final ApplyHouseTemplate _template;

  @override
  Future<Either<Failure, ProjectOverview>> fetch() => _get(projectId!);

  Future<void> setStatus(ProjectStatus status) => runAction(
    () => _update((projectId: projectId!, draft: ProjectDraft(status: status))),
    successMessage: status == ProjectStatus.paused
        ? 'Project paused. Your site manager has been told to stop work.'
        : 'Project resumed.',
  );

  Future<void> removeMember(ProjectMember member) => runAction(
    () => _remove((projectId: projectId!, userId: member.userId)),
    successMessage: '${member.displayName} removed from the project.',
  );

  Future<void> applyTemplate() => runAction(
    () => _template((
      projectId: projectId!,
      totalBudget: state.data?.project.plannedBudget,
      start: DateTime.now(),
    )),
    successMessage: 'Added Foundation, Walling, Roofing and Finishing.',
  );
}

enum ProjectFormStatus { editing, locating, saving, saved }

final class ProjectFormState extends Equatable {
  const ProjectFormState({
    this.status = ProjectFormStatus.editing,
    this.latitude,
    this.longitude,
    this.suggestedAddress,
    this.targetDate,
    this.saved,
    this.error,
  });

  final ProjectFormStatus status;
  final double? latitude;
  final double? longitude;

  /// Reverse-geocoded address for the pin; the field stays editable.
  final String? suggestedAddress;
  final DateTime? targetDate;
  final Project? saved;
  final String? error;

  bool get hasPin => latitude != null && longitude != null;

  ProjectFormState copyWith({
    ProjectFormStatus? status,
    double? latitude,
    double? longitude,
    String? suggestedAddress,
    DateTime? targetDate,
    Project? saved,
    String? error,
  }) => ProjectFormState(
    status: status ?? this.status,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    suggestedAddress: suggestedAddress ?? this.suggestedAddress,
    targetDate: targetDate ?? this.targetDate,
    saved: saved ?? this.saved,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    latitude,
    longitude,
    suggestedAddress,
    targetDate,
    saved,
    error,
  ];
}

/// Create project (onboarding step 3) and edit "Name, site & budget".
@injectable
class ProjectFormCubit extends Cubit<ProjectFormState> {
  ProjectFormCubit(this._create, this._update, this._location, this._geocoder)
    : super(const ProjectFormState());

  final CreateProject _create;
  final UpdateProject _update;
  final LocationService _location;
  final GeocodingService _geocoder;

  void loadExisting(Project p) => emit(
    ProjectFormState(
      latitude: p.latitude,
      longitude: p.longitude,
      targetDate: p.targetCompletionDate,
    ),
  );

  /// Drops the pin at the phone's position and suggests an address.
  Future<void> dropPinHere() async {
    emit(state.copyWith(status: ProjectFormStatus.locating));
    try {
      final fix = await _location.currentFix();
      final address = await _geocoder.reverseGeocode(
        fix.latitude,
        fix.longitude,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProjectFormStatus.editing,
          latitude: fix.latitude,
          longitude: fix.longitude,
          suggestedAddress: address,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProjectFormStatus.editing,
          error: 'Couldn\'t get your location. Check location access.',
        ),
      );
    }
  }

  void targetDateChanged(DateTime date) =>
      emit(state.copyWith(targetDate: date));

  Future<void> submit({
    String? projectId,
    required String name,
    required String address,
    required String description,
    required double? budget,
  }) async {
    if (!state.hasPin) {
      return emit(state.copyWith(error: 'Drop the site pin first.'));
    }
    emit(state.copyWith(status: ProjectFormStatus.saving));
    final draft = ProjectDraft(
      projectName: name.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      latitude: state.latitude,
      longitude: state.longitude,
      locationName: address.trim(),
      plannedBudget: budget,
      currency: 'UGX',
      targetCompletionDate: state.targetDate,
    );
    final result = projectId == null
        ? await _create(draft)
        : await _update((projectId: projectId, draft: draft));
    if (isClosed) return;
    emit(
      result.match(
        (f) =>
            state.copyWith(status: ProjectFormStatus.editing, error: f.message),
        (p) => state.copyWith(status: ProjectFormStatus.saved, saved: p),
      ),
    );
  }
}

/// "Add your site manager" (onboarding step 5) and adding from settings.
@injectable
class TeamCubit extends LoadCubit<List<ProjectMember>> {
  TeamCubit(
    @factoryParam this.projectId,
    this._list,
    this._invite,
    DataChanges changes,
  ) : super(changes, {DataTopic.members});

  final String? projectId;
  final ListProjectMembers _list;
  final InviteMember _invite;

  @override
  Future<Either<Failure, List<ProjectMember>>> fetch() => _list(projectId!);

  Future<bool> invite(String email) => runAction(
    () => _invite((
      projectId: projectId!,
      email: email,
      role: ProjectRole.projectManager,
    )),
  );
}
