import 'package:app/core/error/failures.dart';
import 'package:app/features/projects/domain/usecases/project_usecases.dart';
import 'package:app/features/projects/presentation/bloc/accept_invite_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAcceptInvitation extends Mock implements AcceptInvitation {}

void main() {
  late _MockAcceptInvitation acceptInvitation;

  setUp(() => acceptInvitation = _MockAcceptInvitation());

  blocTest<AcceptInviteCubit, AcceptInviteState>(
    'accepting a valid token yields the project to open',
    setUp: () => when(
      () => acceptInvitation('tok-123'),
    ).thenAnswer((_) async => const Right('prj-9')),
    build: () => AcceptInviteCubit(acceptInvitation),
    act: (cubit) => cubit.accept('tok-123'),
    expect: () => const [
      AcceptInviteState.accepting(),
      AcceptInviteState.accepted('prj-9'),
    ],
  );

  blocTest<AcceptInviteCubit, AcceptInviteState>(
    'shows the server\'s reason when the invite is rejected',
    setUp: () => when(() => acceptInvitation('tok-old')).thenAnswer(
      (_) async =>
          const Left(ServerFailure('Invitation has expired', statusCode: 400)),
    ),
    build: () => AcceptInviteCubit(acceptInvitation),
    act: (cubit) => cubit.accept('tok-old'),
    expect: () => const [
      AcceptInviteState.accepting(),
      AcceptInviteState.failed('Invitation has expired'),
    ],
  );

  blocTest<AcceptInviteCubit, AcceptInviteState>(
    'a link without a token fails without calling the server',
    build: () => AcceptInviteCubit(acceptInvitation),
    act: (cubit) => cubit.accept(''),
    expect: () => const [
      AcceptInviteState.failed('This invite link is incomplete.'),
    ],
    verify: (_) => verifyNever(() => acceptInvitation(any())),
  );
}
