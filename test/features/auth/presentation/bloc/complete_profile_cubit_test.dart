import 'package:app/core/error/failures.dart';
import 'package:app/features/auth/domain/entities/profile_update.dart';
import 'package:app/features/auth/domain/entities/user_role.dart';
import 'package:app/features/auth/presentation/bloc/complete_profile_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockUpdateProfile updateProfile;

  setUpAll(() => registerFallbackValue(const ProfileUpdate()));
  setUp(() => updateProfile = MockUpdateProfile());

  CompleteProfileCubit build() => CompleteProfileCubit(updateProfile);

  Future<void> submit(CompleteProfileCubit cubit) => cubit.submit(
    firstName: ' Sarah ',
    middleName: '  ',
    lastName: 'Namuli',
    email: 'sarah@example.com ',
    phone: '+447700900123',
  );

  blocTest<CompleteProfileCubit, CompleteProfileState>(
    'submitting without a role flags it and does not call the API',
    build: build,
    act: submit,
    expect: () => [const CompleteProfileState(showRoleError: true)],
    verify: (_) => verifyNever(() => updateProfile(any())),
  );

  blocTest<CompleteProfileCubit, CompleteProfileState>(
    'sends trimmed fields with user_role and exposes the saved user',
    build: build,
    setUp: () => when(
      () => updateProfile(any()),
    ).thenAnswer((_) async => const Right(tOwner)),
    act: (cubit) async {
      cubit.roleSelected(UserRole.owner);
      await submit(cubit);
    },
    expect: () => [
      const CompleteProfileState(role: UserRole.owner),
      const CompleteProfileState(
        role: UserRole.owner,
        status: CompleteProfileStatus.submitting,
      ),
      const CompleteProfileState(
        role: UserRole.owner,
        status: CompleteProfileStatus.saved,
        savedUser: tOwner,
      ),
    ],
    verify: (_) => verify(
      () => updateProfile(
        const ProfileUpdate(
          firstName: 'Sarah',
          lastName: 'Namuli',
          contactEmail: 'sarah@example.com',
          contactPhone: '+447700900123',
          userRole: UserRole.owner,
        ),
      ),
    ).called(1),
  );

  blocTest<CompleteProfileCubit, CompleteProfileState>(
    'API failure returns to editing with the message',
    build: build,
    seed: () => const CompleteProfileState(role: UserRole.manager),
    setUp: () => when(() => updateProfile(any())).thenAnswer(
      (_) async => const Left(ServerFailure('contact_email is required')),
    ),
    act: submit,
    skip: 1,
    expect: () => [
      const CompleteProfileState(
        role: UserRole.manager,
        error: 'contact_email is required',
      ),
    ],
  );
}
