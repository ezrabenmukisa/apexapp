import 'package:equatable/equatable.dart';

/// The project's site pin and the address shown for it.
class SiteLocation extends Equatable {
  const SiteLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;

  /// Reverse-geocoded address; null until looked up (or when none found).
  final String? address;

  @override
  List<Object?> get props => [latitude, longitude, address];
}
