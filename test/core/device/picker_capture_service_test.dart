import 'dart:io';

import 'package:app/core/device/device_services.dart';
import 'package:app/core/device/real_device_services.dart';
import 'package:app/features/evidence/domain/entities/evidence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockPicker extends Mock implements ImagePicker {}

class _FakeLocation implements LocationService {
  final fixes = <Object>[]; // GeoFix or an error to throw, in order

  @override
  Future<GeoFix> currentFix() async {
    final next = fixes.removeAt(0);
    if (next is GeoFix) return next;
    throw next;
  }
}

class _FakeStore implements MediaStore {
  final kept = <String>[];

  @override
  Future<String> keep(XFile file, String id) async {
    kept.add(file.path);
    return '/kept/$id';
  }
}

GeoFix _fix(double lat) => GeoFix(
  latitude: lat,
  longitude: 32.4,
  accuracyMetres: 5,
  timestamp: DateTime(2026, 11, 5, 10),
);

void main() {
  late _MockPicker picker;
  late _FakeLocation location;
  late _FakeStore store;
  late PickerCaptureService service;
  late File shot;

  setUpAll(() => registerFallbackValue(ImageSource.camera));

  setUp(() {
    picker = _MockPicker();
    location = _FakeLocation();
    store = _FakeStore();
    service = PickerCaptureService(location, picker, store);
    shot = File('${Directory.systemTemp.path}/apex_shot.jpg')
      ..writeAsBytesSync([1, 2, 3]);
  });

  void cameraReturns(XFile? file) {
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        imageQuality: any(named: 'imageQuality'),
        requestFullMetadata: any(named: 'requestFullMetadata'),
      ),
    ).thenAnswer((_) async => file);
  }

  test('a photo keeps the file and the fix taken after the shot', () async {
    location.fixes.addAll([_fix(0.1), _fix(0.2)]);
    cameraReturns(XFile(shot.path));

    final media = await service.takePhoto();

    expect(media!.kind, MediaKind.photo);
    expect(media.localPath, startsWith('/kept/'));
    expect(media.fix.latitude, 0.2);
    expect(store.kept, [shot.path]);
    verify(
      () => picker.pickImage(
        source: ImageSource.camera,
        maxWidth: any(named: 'maxWidth'),
        imageQuality: any(named: 'imageQuality'),
        requestFullMetadata: any(named: 'requestFullMetadata'),
      ),
    ).called(1);
  });

  test('closing the camera without a shot returns null', () async {
    location.fixes.add(_fix(0.1));
    cameraReturns(null);

    expect(await service.takePhoto(), isNull);
    expect(store.kept, isEmpty);
  });

  test('no location means the camera never opens', () async {
    location.fixes.add(const DeviceException('Turn on location.'));

    await expectLater(service.takePhoto(), throwsA(isA<DeviceException>()));
    verifyNever(
      () => picker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        imageQuality: any(named: 'imageQuality'),
        requestFullMetadata: any(named: 'requestFullMetadata'),
      ),
    );
  });

  test('if GPS drops after the shot, the fix from before is used', () async {
    location.fixes.addAll([_fix(0.1), StateError('timeout')]);
    cameraReturns(XFile(shot.path));

    final media = await service.takePhoto();

    expect(media!.fix.latitude, 0.1);
  });

  test(
    'camera permission refused becomes a readable DeviceException',
    () async {
      location.fixes.add(_fix(0.1));
      when(
        () => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          imageQuality: any(named: 'imageQuality'),
          requestFullMetadata: any(named: 'requestFullMetadata'),
        ),
      ).thenThrow(PlatformException(code: 'camera_access_denied'));

      await expectLater(
        service.takePhoto(),
        throwsA(
          isA<DeviceException>().having(
            (e) => e.message,
            'message',
            contains('camera'),
          ),
        ),
      );
    },
  );

  test('a video records up to the limit from the rear camera', () async {
    location.fixes.addAll([_fix(0.1), _fix(0.2)]);
    when(
      () => picker.pickVideo(
        source: any(named: 'source'),
        maxDuration: any(named: 'maxDuration'),
      ),
    ).thenAnswer((_) async => XFile(shot.path));

    final media = await service.recordVideo(
      maxDuration: const Duration(minutes: 1),
    );

    expect(media!.kind, MediaKind.video);
    verify(
      () => picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      ),
    ).called(1);
  });
}
