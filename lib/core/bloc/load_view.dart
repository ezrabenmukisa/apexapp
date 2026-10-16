import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/snackbar.dart';
import '../widgets/common.dart';
import 'load_cubit.dart';

/// Renders a [LoadCubit]: spinner on first load, error with retry, then
/// [builder] with data. Shows action messages as snackbars.
class LoadView<C extends LoadCubit<T>, T> extends StatelessWidget {
  const LoadView({super.key, required this.builder, this.onActionSuccess});

  final Widget Function(BuildContext context, T data, LoadState<T> state)
  builder;

  /// Called once when an action succeeds (e.g. pop the page).
  final void Function(BuildContext context, LoadState<T> state)?
  onActionSuccess;

  @override
  Widget build(BuildContext context) => BlocConsumer<C, LoadState<T>>(
    listenWhen: (a, b) =>
        a.action != b.action || a.actionMessage != b.actionMessage,
    listener: (context, state) {
      if (state.actionMessage != null && state.action != ActionStatus.busy) {
        context.showMessage(state.actionMessage!);
      }
      if (state.action == ActionStatus.success) {
        onActionSuccess?.call(context, state);
      }
    },
    builder: (context, state) {
      final data = state.data;
      if (data != null) return builder(context, data, state);
      if (state.failure != null) {
        return ErrorView(
          message: state.failure!.message,
          onRetry: context.read<C>().load,
        );
      }
      return const LoadingView();
    },
  );
}
