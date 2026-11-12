import 'package:app/core/device/place_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> feature(Map<String, dynamic> props, {double lat = 1}) =>
      {
        'geometry': {
          'type': 'Point',
          'coordinates': [32.5, lat],
        },
        'properties': props,
      };

  test('maps Photon features to title + area, nearest first', () {
    final result = PhotonPlaceSearch.parse({
      'features': [
        feature({
          'name': 'Nakasero Market',
          'street': 'Market St',
          'city': 'Kampala',
          'country': 'Uganda',
        }),
        feature({
          'street': 'Speke Road',
          'housenumber': '12',
          'district': 'Nakasero',
          'city': 'Kampala',
          'country': 'Uganda',
        }, lat: 2),
      ],
    });
    expect(result, const [
      PlaceSuggestion(
        title: 'Nakasero Market',
        subtitle: 'Market St, Kampala, Uganda',
        latitude: 1,
        longitude: 32.5,
      ),
      PlaceSuggestion(
        title: 'Speke Road 12',
        subtitle: 'Nakasero, Kampala, Uganda',
        latitude: 2,
        longitude: 32.5,
      ),
    ]);
  });

  test('skips unnamed places, duplicates and bad geometry', () {
    final result = PhotonPlaceSearch.parse({
      'features': [
        feature({'city': 'Kampala'}),
        feature({'name': 'Mukono', 'country': 'Uganda'}),
        feature({'name': 'Mukono', 'country': 'Uganda'}, lat: 3),
        {
          'geometry': null,
          'properties': {'name': 'X'},
        },
      ],
    });
    expect(result.map((p) => p.title), ['Mukono']);
  });

  test('a malformed response gives no suggestions', () {
    expect(PhotonPlaceSearch.parse(null), isEmpty);
    expect(PhotonPlaceSearch.parse({'features': 'oops'}), isEmpty);
  });
}
