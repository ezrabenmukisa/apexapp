import 'dart:async';

import 'package:app/core/device/device_services.dart';
import 'package:app/core/device/place_search.dart';
import 'package:app/features/evidence/domain/entities/evidence.dart';
import 'package:app/features/projects/domain/entities/site_location.dart';
import 'package:app/features/projects/presentation/bloc/location_picker_cubit.dart';
import 'package:app/features/projects/presentation/widgets/site_map_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocation extends Mock implements LocationService {}

class _MockGeocoder extends Mock implements GeocodingService {}

class _MockPlaces extends Mock implements PlaceSearchService {}

void main() {
  late _MockLocation location;
  late _MockGeocoder geocoder;
  late _MockPlaces places;

  const nakasero = (latitude: 0.3163, longitude: 32.5822);
  final fix = GeoFix(
    latitude: 0.33184,
    longitude: 32.56334,
    accuracyMetres: 5,
    timestamp: DateTime(2026, 11, 6),
  );

  setUp(() {
    location = _MockLocation();
    geocoder = _MockGeocoder();
    places = _MockPlaces();
  });

  LocationPickerCubit build() =>
      LocationPickerCubit(location, geocoder, places);

  const market = PlaceSuggestion(
    title: 'Nakasero Market',
    subtitle: 'Kampala, Uganda',
    latitude: 0.3136,
    longitude: 32.5791,
  );

  group('start', () {
    test('opens on the existing pin', () async {
      final cubit = build();
      final start = await cubit.start(
        const SiteLocation(latitude: 1, longitude: 2, address: 'Mukono'),
      );
      expect(start, (latitude: 1.0, longitude: 2.0));
      expect(cubit.state.address, 'Mukono');
      verifyNever(() => location.currentFix());
    });

    test('opens on the phone\'s position when there is no pin', () async {
      when(() => location.currentFix()).thenAnswer((_) async => fix);
      expect(await build().start(null), (
        latitude: fix.latitude,
        longitude: fix.longitude,
      ));
    });

    test('falls back to Kampala when GPS is unavailable', () async {
      when(
        () => location.currentFix(),
      ).thenThrow(const DeviceException('Location is off'));
      expect(await build().start(null), kampala);
    });
  });

  blocTest<LocationPickerCubit, LocationPickerState>(
    'moving the pin looks up the address under it',
    build: build,
    setUp: () => when(
      () => geocoder.reverseGeocode(nakasero.latitude, nakasero.longitude),
    ).thenAnswer((_) async => 'Speke Rd, Nakasero, Kampala, Uganda'),
    act: (cubit) => cubit.pinMoved(nakasero),
    expect: () => [
      const LocationPickerState(target: nakasero, resolvingAddress: true),
      const LocationPickerState(
        target: nakasero,
        address: 'Speke Rd, Nakasero, Kampala, Uganda',
      ),
    ],
    verify: (cubit) => expect(
      cubit.state.result,
      const SiteLocation(
        latitude: 0.3163,
        longitude: 32.5822,
        address: 'Speke Rd, Nakasero, Kampala, Uganda',
      ),
    ),
  );

  test('a slow lookup for an old pin never overwrites the newer one', () async {
    final slow = Completer<String>();
    when(() => geocoder.reverseGeocode(1, 1)).thenAnswer((_) => slow.future);
    when(() => geocoder.reverseGeocode(2, 2)).thenAnswer((_) async => 'Newer');
    final cubit = build();

    final first = cubit.pinMoved((latitude: 1, longitude: 1));
    await cubit.pinMoved((latitude: 2, longitude: 2));
    slow.complete('Older');
    await first;

    expect(cubit.state.target, (latitude: 2.0, longitude: 2.0));
    expect(cubit.state.address, 'Newer');
  });

  blocTest<LocationPickerCubit, LocationPickerState>(
    'no address is not an error: the pin can still be confirmed',
    build: build,
    setUp: () => when(
      () => geocoder.reverseGeocode(any(), any()),
    ).thenThrow(const DeviceException('No address found for this spot.')),
    act: (cubit) => cubit.pinMoved(nakasero),
    skip: 1,
    expect: () => [const LocationPickerState(target: nakasero)],
    verify: (cubit) => expect(cubit.state.canConfirm, isTrue),
  );

  blocTest<LocationPickerCubit, LocationPickerState>(
    'search moves the map to the match',
    build: build,
    setUp: () => when(
      () => geocoder.forwardGeocode('Speke Road'),
    ).thenAnswer((_) async => nakasero),
    act: (cubit) => cubit.search('Speke Road'),
    expect: () => [
      const LocationPickerState(searching: true),
      const LocationPickerState(moveTo: nakasero, moveSeq: 1),
    ],
  );

  blocTest<LocationPickerCubit, LocationPickerState>(
    'search with no match says so',
    build: build,
    setUp: () => when(
      () => geocoder.forwardGeocode(any()),
    ).thenAnswer((_) async => null),
    act: (cubit) => cubit.search('zzzz'),
    skip: 1,
    expect: () => [
      isA<LocationPickerState>().having(
        (s) => s.message,
        'message',
        contains('No place found for "zzzz"'),
      ),
    ],
  );

  blocTest<LocationPickerCubit, LocationPickerState>(
    'my location explains when location is off',
    build: build,
    setUp: () => when(
      () => location.currentFix(),
    ).thenThrow(const DeviceException('Turn on location (GPS).')),
    act: (cubit) => cubit.useMyLocation(),
    expect: () => [
      const LocationPickerState(locating: true),
      const LocationPickerState(message: 'Turn on location (GPS).'),
    ],
  );

  group('suggestions', () {
    const wait = LocationPickerCubit.suggestDelay;

    blocTest<LocationPickerCubit, LocationPickerState>(
      'typing pauses, then matches near the pin are listed',
      build: build,
      seed: () => const LocationPickerState(target: nakasero),
      setUp: () => when(
        () => places.suggest('Nakas', near: nakasero),
      ).thenAnswer((_) async => [market]),
      act: (cubit) => cubit
        ..queryChanged('Na')
        ..queryChanged('Naka')
        ..queryChanged('Nakas'),
      wait: wait * 2,
      expect: () => [
        const LocationPickerState(target: nakasero, suggesting: true),
        const LocationPickerState(target: nakasero, suggestions: [market]),
      ],
      // Only the last keystroke reaches the network.
      verify: (_) => verify(
        () => places.suggest(any(), near: any(named: 'near')),
      ).called(1),
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'too short a query clears the list',
      build: build,
      seed: () => const LocationPickerState(suggestions: [market]),
      act: (cubit) => cubit.queryChanged('Na'),
      expect: () => [const LocationPickerState()],
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'choosing one moves the map there and closes the list',
      build: build,
      seed: () => const LocationPickerState(suggestions: [market]),
      act: (cubit) => cubit.suggestionChosen(market),
      expect: () => [LocationPickerState(moveTo: market.point, moveSeq: 1)],
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'Search takes the top suggestion without the phone geocoder',
      build: build,
      seed: () => const LocationPickerState(suggestions: [market]),
      act: (cubit) => cubit.search('Nakasero'),
      expect: () => [LocationPickerState(moveTo: market.point, moveSeq: 1)],
      verify: (_) => verifyNever(() => geocoder.forwardGeocode(any())),
    );

    test('a late answer for an old query is ignored', () async {
      final slow = Completer<List<PlaceSuggestion>>();
      when(
        () => places.suggest('Nakasero', near: any(named: 'near')),
      ).thenAnswer((_) => slow.future);
      final cubit = build()..queryChanged('Nakasero');
      await Future<void>.delayed(wait * 2);
      cubit.queryChanged('Na');
      slow.complete([market]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.suggestions, isEmpty);
      await cubit.close();
    });
  });
}
