import 'package:flutter/material.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/primary_button.dart';

/// Localized error message: network → generic message, otherwise the
/// backend's `{ error }` message (already localized via
/// Accept-Language — e.g. the EPL minimum of CHF 20'000).
String scenarioErrorMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      NetworkException() => l10n.errorNetwork,
      ApiException(:final message) => message,
      _ => l10n.errorUnknown,
    };

/// Label + value row for results (equivalent of iOS's `MetricRow`).
class ScenarioMetricRow extends StatelessWidget {
  const ScenarioMetricRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.suffix,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// Detail shown below the value (e.g. "You receive").
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Section title within a results card.
class ScenarioSectionTitle extends StatelessWidget {
  const ScenarioSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

/// Contextual info card (tip, disclaimer): icon + text.
class ScenarioInfoCard extends StatelessWidget {
  const ScenarioInfoCard({
    required this.icon,
    required this.text,
    this.color,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-blocking banner shown at the top of the screen when the
/// profile prefill failed: the form stays usable with default
/// values, retry reloads the profile.
class ScenarioPrefillBanner extends StatelessWidget {
  const ScenarioPrefillBanner({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.scenarioPrefillFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}

/// Error card with retry — inline below the form after a failed
/// calculation (the input is preserved, the user can correct it).
class ScenarioErrorCard extends StatelessWidget {
  const ScenarioErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
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
        ],
      ),
    );
  }
}

/// Slider input row: label + current value on the right, slider
/// below (age, years, number of accounts).
class ScenarioSliderRow extends StatelessWidget {
  const ScenarioSliderRow({
    required this.label,
    required this.value,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final String label;

  /// Displayed value (e.g. "35", "2").
  final String value;
  final double sliderValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: sliderValue,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
