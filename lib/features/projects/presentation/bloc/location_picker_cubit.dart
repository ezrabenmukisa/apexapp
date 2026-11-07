import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/device_services.dart';
import '../../domain/entities/site_location.dart';
import '../widgets/site_map_view.dart';

final class LocationPickerState extends Equatable {
  const LocationPickerState({
    this.target,
    this.address,
    this.resolvingAddress = false,
    this.searching = false,
    this.locating = false,
    this.moveTo,
    this.moveSeq = 0,
    this.message,
  });

  /// Where the pin is (the map centre); null until the map is ready.
  final LatLngPoint? target;
  final String? address;
  final bool resolvingAddress;
  final bool searching;
  final bool locating;

  /// Camera command for the page: move the map here (search, my location).
  /// [moveSeq] changes on every command so repeats still fire.
  final LatLngPoint? moveTo;
  final int moveSeq;

  /// One-shot message (no results, location off…).
  final String? message;

  bool get canConfirm => target != null && !resolvingAddress;

  SiteLocation? get result => target == null
      ? null
      : SiteLocation(
          latitude: target!.latitude,
          longitude: target!.longitude,
          address: address,
        );

  LocationPickerState copyWith({
    LatLngPoint? target,
    String? address,
    bool clearAddress = false,
    bool? resolvingAddress,
    bool? searching,
    bool? locating,
    LatLngPoint? moveTo,
    String? message,
  }) => LocationPickerState(
    target: target ?? this.target,
    address: clearAddress ? null : (address ?? this.address),
    resolvingAddress: resolvingAddress ?? this.resolvingAddress,
    searching: searching ?? this.searching,
    locating: locating ?? this.locating,
    moveTo: moveTo ?? this.moveTo,
    moveSeq: moveTo == null ? moveSeq : moveSeq + 1,
    message: message,
  );

  @override
  List<Object?> get props => [
    target,
    address,
    resolvingAddress,
    searching,
    locating,
    moveTo,
    moveSeq,
    message,
  ];
}

/// Full-screen site pin picker: pan the map (or search, or use GPS) and the
/// address under the pin is looked up when the map stops moving.
@injectable
class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit(this._location, this._geocoder)
    : super(const LocationPickerState());

  final LocationService _location;
  final GeocodingService _geocoder;

  /// Only the newest lookup may update the address.
  int _lookup = 0;

  /// Where to open the map. With an existing pin that's it; otherwise the
  /// phone's position (falls back to Kampala if GPS is unavailable).
  Future<LatLngPoint> start(SiteLocation? initial) async {
    if (initial != null) {
      emit(
        state.copyWith(
          target: (latitude: initial.latitude, longitude: initial.longitude),
          address: initial.address,
        ),
      );
      return (latitude: initial.latitude, longitude: initial.longitude);
    }
    try {
      final fix = await _location.currentFix();
      return (latitude: fix.latitude, longitude: fix.longitude);
    } catch (_) {
      return kampala;
    }
  }

  /// The map stopped moving with its centre (the pin) at [point].
  Future<void> pinMoved(LatLngPoint point) async {
    if (point == state.target && state.address != null) return;
    final lookup = ++_lookup;
    emit(
      state.copyWith(target: point, resolvingAddress: true, clearAddress: true),
    );
    String? address;
    try {
      address = await _geocoder.reverseGeocode(point.latitude, point.longitude);
    } catch (_) {
      address = null; // Shown as "No address found"; the field stays editable.
    }
    if (isClosed || lookup != _lookup) return;
    emit(state.copyWith(address: address, resolvingAddress: false));
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty || state.searching) return;
    emit(state.copyWith(searching: true));
    final found = await _geocoder.forwardGeocode(query);
    if (isClosed) return;
    emit(
      found == null
          ? state.copyWith(
              searching: false,
              message:
                  'No place found for "${query.trim()}". Try a nearby town or landmark.',
            )
          : state.copyWith(searching: false, moveTo: found),
    );
  }

  Future<void> useMyLocation() async {
    if (state.locating) return;
    emit(state.copyWith(locating: true));
    try {
      final fix = await _location.currentFix();
      if (isClosed) return;
      emit(
        state.copyWith(
          locating: false,
          moveTo: (latitude: fix.latitude, longitude: fix.longitude),
        ),
      );
    } on DeviceException catch (e) {
      if (!isClosed) emit(state.copyWith(locating: false, message: e.message));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            locating: false,
            message: 'Couldn\'t get your location. Check location access.',
          ),
        );
      }
    }
  }
}
