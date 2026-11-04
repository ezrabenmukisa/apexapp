import 'package:injectable/injectable.dart';

/// The token from an invite link opened while signed out (or before the
/// profile was complete). The router sends the user back to the invite once
/// they're signed in; the invite page clears it when it takes the token.
@lazySingleton
class PendingInvite {
  String? token;
}
