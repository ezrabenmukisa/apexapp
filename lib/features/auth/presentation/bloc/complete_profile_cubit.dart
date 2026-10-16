import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/usecases/profile_usecases.dart';

enum CompleteProfileStatus { editing, submitting, saved }

final class CompleteProfileState extends Equatable {
  const CompleteProfileState({
    this.role,
    this.status = CompleteProfileStatus.editing,
    this.savedUser,
    this.error,
    this.showRoleError = false,
  });

  final UserRole? role;
  final CompleteProfileStatus status;
  final AppUser? savedUser;
  final String? error;

  /// Submit was attempted without choosing a role.
  final bool showRoleError;

  bool get isSubmitting => status == CompleteProfileStatus.submitting;

  CompleteProfileState copyWith({
    UserRole? role,
    CompleteProfileStatus? status,
    AppUser? savedUser,
    String? error,
    bool? showRoleError,
  }) => CompleteProfileState(
    role: role ?? this.role,
    status: status ?? this.status,
    savedUser: savedUser ?? this.savedUser,
    error: error,
    showRoleError: showRoleError ?? this.showRoleError,
  );

  @override
  List<Object?> get props => [role, status, savedUser, error, showRoleError];
}

/// Onboarding step 2: name, contact details and role → `PATCH /users/me`.
@injectable
class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  CompleteProfileCubit(this._updateProfile)
    : super(const CompleteProfileState());

  final UpdateProfile _updateProfile;

  void roleSelected(UserRole role) =>
      emit(state.copyWith(role: role, showRoleError: false));

  /// Flags a missing role so it shows alongside form field errors.
  bool validateRole() {
    if (state.role != null) return true;
    emit(state.copyWith(showRoleError: true));
    return false;
  }

  Future<void> submit({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    if (state.isSubmitting) return;
    final role = state.role;
    if (role == null) {
      validateRole();
      return;
    }
    emit(state.copyWith(status: CompleteProfileStatus.submitting));

    final result = await _updateProfile(
      ProfileUpdate(
        firstName: firstName.trim(),
        middleName: _nullIfBlank(middleName),
        lastName: lastName.trim(),
        contactEmail: email.trim(),
        contactPhone: _nullIfBlank(phone),
        userRole: role,
      ),
    );
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(
          status: CompleteProfileStatus.editing,
          error: failure.message,
        ),
        (user) => state.copyWith(
          status: CompleteProfileStatus.saved,
          savedUser: user,
        ),
      ),
    );
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
