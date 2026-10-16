import 'package:app/features/auth/data/datasources/auth_api_data_source.dart';
import 'package:app/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:app/features/auth/data/datasources/profile_api_data_source.dart';
import 'package:app/features/auth/data/datasources/session_local_data_source.dart';
import 'package:app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app/features/auth/domain/usecases/profile_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockAuthApiDataSource extends Mock implements AuthApiDataSource {}

class MockProfileApiDataSource extends Mock implements ProfileApiDataSource {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

class MockWatchAuthIdentity extends Mock implements WatchAuthIdentity {}

class MockEstablishSession extends Mock implements EstablishSession {}

class MockGetProfile extends Mock implements GetProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockSignOut extends Mock implements SignOut {}

class MockSendPhoneCode extends Mock implements SendPhoneCode {}

class MockConfirmPhoneCode extends Mock implements ConfirmPhoneCode {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}
