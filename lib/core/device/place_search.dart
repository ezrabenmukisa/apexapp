import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../network/auth_interceptor.dart';
import 'device_services.dart';

/// One search-as-you-type match: a place name plus the area it's in.
final class PlaceSuggestion extends Equatable {
  const PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  /// "Nansana Health Centre IV".
  final String title;

  /// "Nansana, Wakiso, Uganda"; may be empty.
  final String subtitle;
  final double latitude;
  final double longitude;

  LatLngPoint get point => (latitude: latitude, longitude: longitude);

  @override
  List<Object?> get props => [title, subtitle, latitude, longitude];
}

/// Place suggestions while the user types an address, town or landmark.
abstract interface class PlaceSearchService {
  /// Up to a handful of matches for a partial [query], nearest to [near]
  /// first. Empty when nothing matches or the lookup fails.
  Future<List<PlaceSuggestion>> suggest(String query, {LatLngPoint? near});
}

/// OpenStreetMap data through Photon (komoot's public server): built for
/// search-as-you-type, no key or billing, fair use only. The UI shows the
/// required "© OpenStreetMap contributors" credit under the suggestions.
@lazySingleton
class PhotonPlaceSearch implements PlaceSearchService {
  const PhotonPlaceSearch(this._dio);

  final Dio _dio;

  static const _url = 'https://photon.komoot.io/api/';
  static const _limit = 6;

  @override
  Future<List<PlaceSuggestion>> suggest(
    String query, {
    LatLngPoint? near,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _url,
        queryParameters: {
          'q': q,
          'limit': _limit,
          'lang': 'en',
          if (near != null) ...{'lat': near.latitude, 'lon': near.longitude},
        },
        // Not the Apex API: never send the Firebase token here.
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );
      return parse(response.data);
    } catch (_) {
      // Suggestions are a convenience; typing + Search still works.
      return const [];
    }
  }

  /// Photon GeoJSON → suggestions, skipping unnamed and duplicate places.
  static List<PlaceSuggestion> parse(Map<String, dynamic>? json) {
    final features = json?['features'];
    if (features is! List) return const [];
    final results = <PlaceSuggestion>[];
    for (final feature in features.whereType<Map<String, dynamic>>()) {
      final coords = (feature['geometry'] as Map?)?['coordinates'];
      final props = feature['properties'];
      if (coords is! List || coords.length < 2 || props is! Map) continue;
      final lng = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      String? s(String key) {
        final v = props[key];
        return v is String && v.trim().isNotEmpty ? v.trim() : null;
      }

      final street = [s('street'), s('housenumber')].nonNulls.join(' ');
      final title = s('name') ?? (street.isEmpty ? null : street);
      if (title == null) continue;

      final area = <String>[];
      for (final part in [
        if (s('name') != null && street.isNotEmpty) street,
        s('district'),
        s('city'),
        s('county'),
        s('state'),
        s('country'),
      ]) {
        if (part == null || part == title || area.contains(part)) continue;
        area.add(part);
      }

      final suggestion = PlaceSuggestion(
        title: title,
        subtitle: area.join(', '),
        latitude: lat,
        longitude: lng,
      );
      final duplicate = results.any(
        (r) => r.title == suggestion.title && r.subtitle == suggestion.subtitle,
      );
      if (!duplicate) results.add(suggestion);
    }
    return results;
  }
}

/// Offline stand-in for tests and demos (`SIMULATE_DEVICE=true`).
@lazySingleton
class SimulatedPlaceSearch implements PlaceSearchService {
  static const _places = [
    PlaceSuggestion(
      title: 'Nansana Trading Centre',
      subtitle: 'Nansana, Wakiso, Uganda',
      latitude: 0.3634,
      longitude: 32.5287,
    ),
    PlaceSuggestion(
      title: 'Nakasero Market',
      subtitle: 'Nakasero, Kampala, Uganda',
      latitude: 0.3136,
      longitude: 32.5791,
    ),
    PlaceSuggestion(
      title: 'Mukono Town',
      subtitle: 'Mukono, Uganda',
      latitude: 0.3533,
      longitude: 32.7553,
    ),
    PlaceSuggestion(
      title: 'Entebbe International Airport',
      subtitle: 'Entebbe, Wakiso, Uganda',
      latitude: 0.0424,
      longitude: 32.4435,
    ),
  ];

  @override
  Future<List<PlaceSuggestion>> suggest(
    String query, {
    LatLngPoint? near,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final p in _places)
        if ('${p.title} ${p.subtitle}'.toLowerCase().contains(q)) p,
    ];
  }
}
