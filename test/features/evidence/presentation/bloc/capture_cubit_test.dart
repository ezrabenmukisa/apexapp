import 'package:app/core/device/device_services.dart';
import 'package:app/features/evidence/domain/entities/evidence.dart';
import 'package:app/features/evidence/presentation/bloc/evidence_cubits.dart';
import 'package:flutter_test/flutter_test.dart';

final _fix = GeoFix(
  latitude: 0.4,
  longitude: 32.4,
  accuracyMetres: 5,
  timestamp: DateTime(2026, 11, 5, 10),
);

class _FakeCapture implements CaptureService {
  Object? next; // CapturedMedia, null (cancelled) or an error to throw
  Duration? videoLimit;

  Future<CapturedMedia?> _answer() async {
    final n = next;
    if (n is CapturedMedia || n == null) return n as CapturedMedia?;
    throw n;
  }

  @override
  Future<CapturedMedia?> takePhoto() => _answer();

  @override
  Future<CapturedMedia?> recordVideo({required Duration maxDuration}) {
    videoLimit = maxDuration;
    return _answer();
  }
}

class _FakeLocation implements LocationService {
  @override
  Future<GeoFix> currentFix() async => _fix;
}

CapturedMedia _media(MediaKind kind) =>
    CapturedMedia(id: 'c1', kind: kind, fix: _fix, localPath: '/kept/c1');

void main() {
  late _FakeCapture capture;
  late CaptureCubit cubit;

  setUp(() {
    capture = _FakeCapture();
    cubit = CaptureCubit(capture, _FakeLocation());
  });
  tearDown(() => cubit.close());

  test('photo mode returns the photo and shows its fix', () async {
    capture.next = _media(MediaKind.photo);

    final media = await cubit.shutter();

    expect(media!.kind, MediaKind.photo);
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.fix, _fix);
  });

  test('video mode opens the recorder once, capped at a minute', () async {
    capture.next = _media(MediaKind.video);
    cubit.setMode(CaptureMode.video);

    final media = await cubit.shutter();

    expect(media!.kind, MediaKind.video);
    expect(capture.videoLimit, CaptureCubit.maxVideoDuration);
  });

  test('cancelling the camera adds nothing', () async {
    capture.next = null;

    expect(await cubit.shutter(), isNull);
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.error, isNull);
  });

  test('a device problem is shown, not thrown', () async {
    capture.next = const DeviceException('Turn on location to capture.');

    expect(await cubit.shutter(), isNull);
    expect(cubit.state.error, 'Turn on location to capture.');
    expect(cubit.state.busy, isFalse);
  });

  test('any other failure gets a generic message', () async {
    capture.next = StateError('plugin blew up');

    expect(await cubit.shutter(), isNull);
    expect(cubit.state.error, contains('camera'));
  });
}
