import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../projects/domain/entities/project_overview.dart';
import '../../../projects/presentation/bloc/project_cubits.dart';
import '../../domain/entities/milestone.dart';
import '../bloc/edit_milestone_cubit.dart';

/// Onboarding 16: create or edit one milestone. [milestoneId] null = new.
class EditMilestonePage extends StatelessWidget {
  const EditMilestonePage({
    super.key,
    required this.projectId,
    this.milestoneId,
  });

  final String projectId;
  final String? milestoneId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProjectOverviewCubit>(param1: projectId)..load(),
    child: Scaffold(
      body: SafeArea(
        child: LoadView<ProjectOverviewCubit, ProjectOverview>(
          builder: (context, o, _) {
            final existing = o.milestones
                .where((m) => m.milestoneId == milestoneId)
                .firstOrNull;
            final last = o.milestones.lastOrNull;
            return BlocProvider(
              create: (_) => getIt<EditMilestoneCubit>()
                ..init(
                  projectId: projectId,
                  existing: existing,
                  count: o.milestones.length,
                  defaultStart: last?.dueDate?.add(const Duration(days: 1)),
                ),
              child: _EditMilestoneForm(
                existing: existing,
                total: o.milestones.length,
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _EditMilestoneForm extends StatefulWidget {
  const _EditMilestoneForm({required this.existing, required this.total});

  final Milestone? existing;
  final int total;

  @override
  State<_EditMilestoneForm> createState() => _EditMilestoneFormState();
}

class _EditMilestoneFormState extends State<_EditMilestoneForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _brief = TextEditingController(text: widget.existing?.description);
  late final _budget = TextEditingController(
    text: widget.existing?.plannedBudget == null
        ? null
        : Formatters.grouped(widget.existing!.plannedBudget!),
  );

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_title, _brief, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<EditMilestoneCubit, EditMilestoneState>(
    listener: (context, state) {
      if (state.error != null) context.showMessage(state.error!);
      if (state.status == EditMilestoneStatus.saved) context.pop();
    },
    builder: (context, state) {
      final cubit = context.read<EditMilestoneCubit>();
      final count = widget.existing == null ? widget.total + 1 : widget.total;
      String two(int n) => n.toString().padLeft(2, '0');
      return Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  BackHeader(
                    close: true,
                    actions: [
                      Text(
                        'MILESTONE ${two(state.sequence)} OF ${two(count)}',
                        style: AppTextStyles.stepLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _title.text.trim().isEmpty
                        ? 'New milestone'
                        : _title.text.trim(),
                    style: AppTextStyles.displayL,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    label: 'Title',
                    child: TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Give it a title'
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Walling',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    label: 'What you expect to see',
                    optional: true,
                    helper:
                        'Your site manager sees this as the brief for this milestone.',
                    child: TextFormField(
                      controller: _brief,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Start',
                          child: DateField(
                            value: state.startDate,
                            onChanged: (d) {
                              if (d != null) cubit.startChanged(d);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabeledField(
                          label: 'Due',
                          optional: true,
                          child: DateField(
                            value: state.dueDate,
                            clearable: true,
                            placeholder: 'None',
                            firstDate: state.startDate,
                            onChanged: cubit.dueChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    label: 'Planned budget',
                    optional: true,
                    child: MoneyField(controller: _budget),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Order', style: AppTextStyles.label),
                      ),
                      _StepButton(
                        icon: Icons.keyboard_arrow_up,
                        tooltip: 'Earlier',
                        onPressed: state.sequence > 1 ? cubit.moveUp : null,
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${state.sequence}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.mono(size: 16, letterSpacing: 0),
                        ),
                      ),
                      _StepButton(
                        icon: Icons.keyboard_arrow_down,
                        tooltip: 'Later',
                        onPressed: state.sequence < state.maxSequence
                            ? cubit.moveDown
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton(
                label: 'Save milestone',
                loading: state.status != EditMilestoneStatus.editing,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  cubit.save(
                    title: _title.text,
                    brief: _brief.text,
                    budget: MoneyField.parse(_budget),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      minimumSize: const Size.square(48),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.controlBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
    ),
  );
}
