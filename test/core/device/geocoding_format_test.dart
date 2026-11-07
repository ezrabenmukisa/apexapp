import 'package:app/core/device/real_device_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  test('formats street, area, town and country without repeats', () {
    expect(
      PlatformGeocodingService.formatPlacemark(
        Placemark(
          street: '1 Speke Rd',
          subLocality: 'Nakasero',
          locality: 'Kampala',
          country: 'Uganda',
        ),
      ),
      '1 Speke Rd, Nakasero, Kampala, Uganda',
    );
    expect(
      PlatformGeocodingService.formatPlacemark(
        Placemark(
          locality: 'Wakiso',
          subAdministrativeArea: 'Wakiso',
          country: 'Uganda',
        ),
      ),
      'Wakiso, Uganda',
    );
  });

  test('skips a bare plus code returned as the street', () {
    expect(
      PlatformGeocodingService.formatPlacemark(
        Placemark(street: '8GJV+2Q8', locality: 'Nansana', country: 'Uganda'),
      ),
      'Nansana, Uganda',
    );
  });
}
