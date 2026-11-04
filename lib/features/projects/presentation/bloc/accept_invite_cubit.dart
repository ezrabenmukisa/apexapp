import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/project_usecases.dart';

enum AcceptInviteStatus { initial, accepting, accepted, failed }

class AcceptInviteState extends Equatable {
  const AcceptInviteState.initial()
    : status = AcceptInviteStatus.initial,
      projectId = null,
      error = null;

  const AcceptInviteState.accepting()
    : status = AcceptInviteStatus.accepting,
      projectId = null,
      error = null;

  const AcceptInviteState.accepted(String this.projectId)
    : status = AcceptInviteStatus.accepted,
      error = null;

  const AcceptInviteState.failed(String this.error)
    : status = AcceptInviteStatus.failed,
      projectId = null;

  final AcceptInviteStatus status;

  /// The project joined, once [AcceptInviteStatus.accepted].
  final String? projectId;
  final String? error;

  @override
  List<Object?> get props => [status, projectId, error];
}

/// Accepts the invite from an emailed `https://apex.pntr.dev/invite?token=…`
/// link. The page opens the project once [AcceptInviteStatus.accepted].
@injectable
class AcceptInviteCubit extends Cubit<AcceptInviteState> {
  AcceptInviteCubit(this._accept) : super(const AcceptInviteState.initial());

  final AcceptInvitation _accept;

  Future<void> accept(String token) async {
    if (token.trim().isEmpty) {
      emit(const AcceptInviteState.failed('This invite link is incomplete.'));
      return;
    }
    emit(const AcceptInviteState.accepting());
    final result = await _accept(token.trim());
    if (isClosed) return;
    emit(
      result.match(
        (f) => AcceptInviteState.failed(f.message),
        AcceptInviteState.accepted,
      ),
    );
  }
}
