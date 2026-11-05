import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/utils/validators.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_cubits.dart';

/// Onboarding 17 (step 5 of 5): invite the site manager by email.
class AddSiteManagerPage extends StatelessWidget {
  const AddSiteManagerPage({
    super.key,
    required this.projectId,
    this.setup = false,
  });

  final String projectId;

  /// Part of the create-project flow (step header, "Finish setup").
  final bool setup;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<TeamCubit>(param1: projectId)..load(),
    child: _AddSiteManagerView(projectId: projectId, setup: setup),
  );
}

class _AddSiteManagerView extends StatefulWidget {
  const _AddSiteManagerView({required this.projectId, required this.setup});

  final String projectId;
  final bool setup;

  @override
  State<_AddSiteManagerView> createState() => _AddSiteManagerViewState();
}

class _AddSiteManagerViewState extends State<_AddSiteManagerView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _note = TextEditingController();

  /// Invites sent from this screen. The API lists people only once they've
  /// accepted, so these are shown separately as pending.
  final _invited = <String>[];

  @override
  void dispose() {
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final sent = await context.read<TeamCubit>().invite(
      email,
      note: _note.text,
    );
    if (sent && mounted) {
      setState(() => _invited.add(email));
      _email.clear();
      _note.clear();
    }
  }

  void _finish() => context.go(AppRoutes.project(widget.projectId));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeamCubit>().state;
    final children = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add your site manager', style: AppTextStyles.displayL),
          const SizedBox(height: 8),
          Text(
            'The contractor or supervisor who will send evidence from site.',
            style: AppTextStyles.body.copyWith(color: AppColors.ink2),
          ),
        ],
      ),
      LabeledField(
        label: 'Their email',
        helper:
            'We email them an invite link. They sign in to Apex with this '
            'email to accept it.',
        child: TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: Validators.email,
        ),
      ),
      LabeledField(
        label: 'Note (optional)',
        helper: 'Added to the invite email.',
        child: TextFormField(
          controller: _note,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Role',
                    style: AppTextStyles.label.copyWith(fontSize: 16),
                  ),
                ),
                const StatusChip(
                  label: 'Site manager',
                  tone: StatusTone.notStarted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Can see the project and milestones and submit evidence. Can\'t change the plan or budgets.',
              style: AppTextStyles.caption.copyWith(color: AppColors.ink2),
            ),
          ],
        ),
      ),
      OutlinedButton(
        onPressed: state.busy ? null : _invite,
        child: state.busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Add to project'),
      ),
      if (_invited.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Invited'),
            AppCardList(
              children: [
                for (final email in _invited)
                  ListRow(
                    leading: const InitialsAvatar('@', size: 32),
                    title: email,
                    subtitle: 'Waiting for them to accept',
                    chevron: false,
                    trailing: const StatusChip(
                      label: 'Invited',
                      tone: StatusTone.awaiting,
                    ),
                  ),
              ],
            ),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('On this project'),
          LoadView<TeamCubit, List<ProjectMember>>(
            builder: (context, members, LoadState<List<ProjectMember>> _) =>
                AppCardList(
                  children: [
                    for (final m in members)
                      ListRow(
                        leading: InitialsAvatar(m.initials, size: 32),
                        title: m.role == ProjectRole.owner
                            ? '${m.displayName} (you)'
                            : m.displayName,
                        subtitle: m.role == ProjectRole.owner
                            ? null
                            : m.contactEmail,
                        chevron: false,
                        trailing: Text(
                          m.role.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        ],
      ),
    ];

    final form = widget.setup
        ? OnboardingScaffold(
            step: 5,
            totalSteps: 5,
            gap: 18,
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(label: 'Finish setup', onPressed: _finish),
                const SizedBox(height: 4),
                Center(child: LinkText('Add later', onTap: _finish)),
              ],
            ),
            children: children,
          )
        : Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const BackHeader(),
                  for (final c in children) ...[c, const SizedBox(height: 18)],
                ],
              ),
            ),
          );
    return Form(key: _formKey, child: form);
  }
}
