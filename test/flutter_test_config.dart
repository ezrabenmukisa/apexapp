import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runs before every test file: tests don't need a real `.env`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  dotenv.loadFromString(
    envString: '''
API_BASE_URL=https://api.test/api/v1
LIVE_PROJECTS=false
LIVE_MILESTONES=false
LIVE_EVIDENCE=false
LIVE_NOTIFICATIONS=false
''',
  );
  await testMain();
}
