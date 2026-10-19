import 'package:app/core/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void load(String env) => dotenv.loadFromString(envString: env);

  tearDown(
    () => load('API_BASE_URL=https://api.test/api/v1\nLIVE_PROJECTS=false'),
  );

  test('reads the base URL and per-feature switches', () {
    load('API_BASE_URL=https://apex.pntr.dev/api/v1\nLIVE_PROJECTS=true');

    AppConfig.validate();
    expect(AppConfig.apiBaseUrl, 'https://apex.pntr.dev/api/v1');
    expect(AppConfig.live.projects, isTrue);
    expect(AppConfig.live.milestones, isFalse, reason: 'missing flags are off');
  });

  test('missing API_BASE_URL stops start-up with a setup hint', () {
    load('LIVE_PROJECTS=false');

    expect(
      AppConfig.validate,
      throwsA(
        isA<ConfigError>().having(
          (e) => e.message,
          'message',
          contains('API_BASE_URL'),
        ),
      ),
    );
  });

  test('rejects a URL without http(s)', () {
    load('API_BASE_URL=apex.pntr.dev');

    expect(AppConfig.validate, throwsA(isA<ConfigError>()));
  });
}
