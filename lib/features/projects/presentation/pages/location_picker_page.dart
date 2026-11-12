import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/device/device_services.dart';
import '../../../../core/device/place_search.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/site_location.dart';
import '../bloc/location_picker_cubit.dart';
import '../widgets/site_map_view.dart';

/// Full-screen map to set the project's site pin: move the map under the
/// pin, tap a spot, search an address (with suggestions as you type) or use
/// the phone's location. Pops
/// with the chosen [SiteLocation].
class LocationPickerPage extends StatelessWidget {
  const LocationPickerPage({super.key, this.initial});

  /// The current pin, if any; the map opens there.
  final SiteLocation? initial;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<LocationPickerCubit>(),
    child: _LocationPickerView(initial: initial),
  );
}

class _LocationPickerView extends StatefulWidget {
  const _LocationPickerView({this.initial});

  final SiteLocation? initial;

  @override
  State<_LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<_LocationPickerView> {
  final _search = TextEditingController();
  late final Future<LatLngPoint> _start;
  SiteMapController? _map;

  @override
  void initState() {
    super.initState();
    _start = context.read<LocationPickerCubit>().start(widget.initial);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submitSearch() {
    FocusScope.of(context).unfocus();
    context.read<LocationPickerCubit>().search(_search.text);
  }

  void _choose(PlaceSuggestion place) {
    _search.value = TextEditingValue(
      text: place.title,
      selection: TextSelection.collapsed(offset: place.title.length),
    );
    FocusScope.of(context).unfocus();
    context.read<LocationPickerCubit>().suggestionChosen(place);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LocationPickerCubit, LocationPickerState>(
        listenWhen: (a, b) => a.moveSeq != b.moveSeq || b.message != null,
        listener: (context, state) {
          if (state.message != null) context.showMessage(state.message!);
          final target = state.moveTo;
          if (target != null) _map?.moveTo(target, zoom: 17);
        },
        builder: (context, state) {
          final cubit = context.read<LocationPickerCubit>();
          return Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Project location',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onChanged: cubit.queryChanged,
                      onSubmitted: (_) => _submitSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search an address, town or landmark',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: state.searching || state.suggesting
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Search',
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _submitSearch,
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FutureBuilder<LatLngPoint>(
                            future: _start,
                            builder: (context, snap) {
                              final start = snap.data;
                              if (start == null) return const LoadingView();
                              return _MapArea(
                                start: start,
                                locating: state.locating,
                                onCreated: (map) => _map = map,
                                onIdle: (point) {
                                  // Panning or tapping the map means the
                                  // list wasn't what they wanted.
                                  cubit.dismissSuggestions();
                                  cubit.pinMoved(point);
                                },
                                onMyLocation: cubit.useMyLocation,
                              );
                            },
                          ),
                        ),
                        if (state.suggestions.isNotEmpty)
                          Positioned(
                            left: AppDimensions.screenGutter,
                            right: AppDimensions.screenGutter,
                            top: 0,
                            child: _SuggestionList(
                              places: state.suggestions,
                              onSelected: _choose,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _ConfirmPanel(
                    state: state,
                    onConfirm: () => context.pop(state.result),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

/// Dropdown of place matches under the search box, floating over the map.
class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.places, required this.onSelected});

  final List<PlaceSuggestion> places;
  final ValueChanged<PlaceSuggestion> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      side: const BorderSide(color: AppColors.rule),
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: places.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.rule),
              itemBuilder: (context, i) =>
                  _SuggestionTile(place: places[i], onTap: onSelected),
            ),
          ),
          // Required credit for OpenStreetMap data.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              '© OpenStreetMap contributors',
              textAlign: TextAlign.end,
              style: AppTextStyles.small.copyWith(color: AppColors.ink3),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.place, required this.onTap});

  final PlaceSuggestion place;
  final ValueChanged<PlaceSuggestion> onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onTap(place),
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.minTouchTarget + 8,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, size: 20, color: AppColors.ink3),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(color: AppColors.ink),
                  ),
                  if (place.subtitle.isNotEmpty)
                    Text(
                      place.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink3,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapArea extends StatelessWidget {
  const _MapArea({
    required this.start,
    required this.locating,
    required this.onCreated,
    required this.onIdle,
    required this.onMyLocation,
  });

  final LatLngPoint start;
  final bool locating;
  final ValueChanged<SiteMapController> onCreated;
  final ValueChanged<LatLngPoint> onIdle;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: SiteMapView(
          initialTarget: start,
          zoom: 17,
          myLocationEnabled: true,
          onMapCreated: onCreated,
          onCameraIdle: onIdle,
        ),
      ),
      // The pin marks the map centre; its tip sits exactly on the point.
      const IgnorePointer(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 44),
            child: Icon(Icons.location_on, size: 44, color: AppColors.laterite),
          ),
        ),
      ),
      Positioned(
        left: 12,
        right: 72,
        top: 12,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
              ),
              child: Text(
                'Move the map or tap to place the pin',
                style: AppTextStyles.small.copyWith(color: AppColors.ink2),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 12,
        bottom: 12,
        child: Material(
          color: AppColors.surface,
          shape: const CircleBorder(side: BorderSide(color: AppColors.rule)),
          elevation: 2,
          child: IconButton(
            tooltip: 'Use my location',
            onPressed: locating ? null : onMyLocation,
            icon: locating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ),
    ],
  );
}

class _ConfirmPanel extends StatelessWidget {
  const _ConfirmPanel({required this.state, required this.onConfirm});

  final LocationPickerState state;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final target = state.target;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.resolvingAddress
                ? 'Finding the address…'
                : (state.address ??
                      (target == null
                          ? ' '
                          : 'No address found — you can type one on the form')),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: state.address == null ? AppColors.ink2 : AppColors.ink,
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(
              Formatters.coordinates(target.latitude, target.longitude),
              style: AppTextStyles.mono(color: AppColors.ink3, size: 11),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Confirm location',
            onPressed: state.canConfirm ? onConfirm : null,
          ),
        ],
      ),
    );
  }
}
