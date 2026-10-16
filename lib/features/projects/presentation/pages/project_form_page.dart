import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_overview.dart';
import '../bloc/project_cubits.dart';
import '../widgets/site_pin_map.dart';

/// Onboarding 14 (step 3 of 5): create a project. With [projectId] it edits
/// "Name, site & budget" instead.
class ProjectFormPage extends StatelessWidget {
  const ProjectFormPage({super.key, this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final id = projectId;
    if (id == null) {
      return BlocProvider(
        create: (_) => getIt<ProjectFormCubit>(),
        child: const _ProjectForm(),
      );
    }
    return BlocProvider(
      create: (_) => getIt<ProjectOverviewCubit>(param1: id)..load(),
      child: Scaffold(
        body: SafeArea(
          child: LoadView<ProjectOverviewCubit, ProjectOverview>(
            builder: (context, o, _) => BlocProvider(
              create: (_) => getIt<ProjectFormCubit>()..loadExisting(o.project),
              child: _ProjectForm(existing: o.project),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({this.existing});

  final Project? existing;

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.projectName);
  late final _address = TextEditingController(
    text: widget.existing?.locationName,
  );
  late final _budget = TextEditingController(
    text: widget.existing?.plannedBudget == null
        ? null
        : Formatters.grouped(widget.existing!.plannedBudget!),
  );
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _address, _budget, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProjectFormCubit>().submit(
      projectId: widget.existing?.projectId,
      name: _name.text,
      address: _address.text,
      description: _description.text,
      budget: MoneyField.parse(_budget),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ProjectFormCubit, ProjectFormState>(
        listener: (context, state) {
          if (state.error != null) context.showMessage(state.error!);
          if (state.suggestedAddress != null &&
              state.suggestedAddress != _address.text &&
              _address.text.isEmpty) {
            _address.text = state.suggestedAddress!;
          }
          if (state.status == ProjectFormStatus.saved) {
            if (_editing) {
              context.showMessage('Project updated.');
              context.pop();
            } else {
              // Continue onboarding: split it into milestones.
              context.pushReplacement(
                AppRoutes.projectPlan(state.saved!.projectId, setup: true),
              );
            }
          }
        },
        builder: (context, state) {
          final cubit = context.read<ProjectFormCubit>();
          final saving =
              state.status == ProjectFormStatus.saving ||
              state.status == ProjectFormStatus.saved;
          final fields = <Widget>[
            Text(
              _editing ? 'Name, site & budget' : 'Your project',
              style: AppTextStyles.displayL,
            ),
            LabeledField(
              label: 'Project name',
              child: TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Name the project' : null,
                decoration: const InputDecoration(
                  hintText: 'e.g. Four-bedroom house',
                ),
              ),
            ),
            LabeledField(
              label: 'Site pin',
              child: SitePinMap(
                latitude: state.latitude,
                longitude: state.longitude,
                locating: state.status == ProjectFormStatus.locating,
                onDropPin: cubit.dropPinHere,
              ),
            ),
            LabeledField(
              label: 'Address',
              helper: 'Filled in from the pin — add directions if it helps.',
              child: TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Add the site address' : null,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: LabeledField(
                    label: 'Budget',
                    optional: true,
                    child: MoneyField(controller: _budget),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 9,
                  child: LabeledField(
                    label: 'Target finish',
                    child: DateField(
                      value: state.targetDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      placeholder: 'Choose',
                      onChanged: (d) {
                        if (d != null) cubit.targetDateChanged(d);
                      },
                    ),
                  ),
                ),
              ],
            ),
            LabeledField(
              label: 'Description',
              optional: true,
              child: TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'e.g. family home, plans approved',
                ),
              ),
            ),
          ];
          final footer = PrimaryButton(
            label: _editing ? 'Save changes' : 'Create project',
            loading: saving,
            onPressed: _submit,
          );
          final form = _editing
              ? Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          const BackHeader(),
                          for (final f in fields) ...[
                            f,
                            const SizedBox(height: 18),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: footer,
                    ),
                  ],
                )
              : OnboardingScaffold(
                  step: 3,
                  totalSteps: 5,
                  gap: 18,
                  footer: footer,
                  children: fields,
                );
          return Form(key: _formKey, child: form);
        },
      );
}
