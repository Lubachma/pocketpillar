import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../application/guided_calculator_controller.dart';
import 'widgets/results_view.dart';
import 'widgets/wizard_steps.dart';

/// Calculator tab: guided flow (4-step wizard → results) —
/// ported from iOS's `GuidedCalculatorView`, calculations via the API (contract §7).
///
/// States: prefill loading, prefill/calculation error with
/// retry, wizard (progress bar), results (with a ↺ button to
/// go back to the wizard, inputs are kept).
///
/// The iOS 3-segment "expert" calculator (`CalculatorView`)
/// is not ported: the guided flow covers all 3 calculations and its free-form
/// fields would duplicate the financial profile (see journal 3.4).
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(guidedCalculatorControllerProvider);
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.hasResults ? l10n.guidedResultsTitle : l10n.guidedTitle,
        ),
        actions: [
          if (state.hasResults)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: l10n.guidedTitle,
              onPressed: controller.restart,
            ),
        ],
      ),
      body: switch ((state, state.prefillLoading)) {
        // Profile API prefill in progress.
        (_, true) => const Center(child: CircularProgressIndicator()),
        _ when state.prefillError != null => _ErrorBody(
          message: _errorMessage(l10n, state.prefillError!),
          onRetry: controller.retryPrefill,
        ),
        _ when state.calculationError != null => _ErrorBody(
          message: _errorMessage(l10n, state.calculationError!),
          onRetry: controller.retryCalculation,
          onBack: controller.clearCalculationError,
        ),
        _ when state.hasResults => ResultsView(
          state: state,
          results: state.results!,
        ),
        _ => _WizardBody(step: state.currentStep),
      },
    );
  }
}

class _WizardBody extends StatelessWidget {
  const _WizardBody({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (step + 1) / guidedStepCount,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.guidedStepOf(step + 1, guidedStepCount),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (step) {
            0 => const SituationStep(),
            1 => const IncomeStep(),
            2 => const Pillar2Step(),
            _ => const Pillar3aStep(),
          },
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: l10n.commonRetry, onPressed: onRetry),
              if (onBack != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onBack,
                    child: Text(l10n.guidedBack),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Localized error message: network → generic message, otherwise the
/// backend's `{ error }` message (already localized via Accept-Language).
String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ApiException(:final message) => message,
  _ => l10n.errorUnknown,
};
