import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../calculator/presentation/widgets/help_sheet.dart';

/// Public methodology document — the app's beginner section links to the
/// same source the README advertises (verifiable Swiss quality).
const String _methodologyUrl =
    'https://github.com/Lubachma/pocketpillar/blob/main/docs/fiscal-accuracy.md';

/// "Understand your pension" — the beginner hub added after the
/// practitioner review (08.2026): an expert had to ask what our inputs
/// meant, so a novice stood no chance. Two parts:
///
/// 1. The 3 pillars — reuses the glossary sheets (`pillar_1_avs`,
///    `pillar_2_bvg`, `pillar_3a`) that existed but were unreachable.
/// 2. "How do we calculate?" — the in-app, plain-words version of
///    `docs/fiscal-accuracy.md`: one block per engine (AVS, LPP, 3a,
///    taxes) plus what we deliberately don't model, and a link to the
///    published methodology.
///
/// Reachable from settings and from the calculator results footer.
class UnderstandScreen extends StatelessWidget {
  const UnderstandScreen({super.key});

  /// Opens the published methodology; on failure (no browser, platform
  /// without a handler), a localized snackbar instead of a silent crash.
  Future<void> _openMethodology(BuildContext context) async {
    try {
      final launched = await launchUrl(
        Uri.parse(_methodologyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('launchUrl returned false');
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorUnknown)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    final calcBlocks = [
      (Icons.people, l10n.understandCalcAvsTitle, l10n.understandCalcAvsBody),
      (Icons.business, l10n.understandCalcLppTitle, l10n.understandCalcLppBody),
      (Icons.payments, l10n.understandCalc3aTitle, l10n.understandCalc3aBody),
      (
        Icons.receipt_long,
        l10n.understandCalcTaxTitle,
        l10n.understandCalcTaxBody,
      ),
      (
        Icons.balance,
        l10n.understandCalcLimitsTitle,
        l10n.understandCalcLimitsBody,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsUnderstandTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.understandIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.understandPillarsTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          _PillarTile(
            icon: Icons.people,
            color: colors.pillar1,
            title: l10n.helpPillar1AvsTitle,
            termId: 'pillar_1_avs',
          ),
          _PillarTile(
            icon: Icons.business,
            color: colors.pillar2,
            title: l10n.helpPillar2BvgTitle,
            termId: 'pillar_2_bvg',
          ),
          _PillarTile(
            icon: Icons.payments,
            color: colors.pillar3a,
            title: l10n.helpPillar3aTitle,
            termId: 'pillar_3a',
          ),
          const SizedBox(height: 24),
          Text(l10n.understandCalcTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.understandCalcIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, body) in calcBlocks)
            _MethodBlock(icon: icon, title: title, body: body),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(
              l10n.understandMethodologyLink,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openMethodology(context),
          ),
        ],
      ),
    );
  }
}

/// One pillar row — tapping opens the pillar's glossary sheet.
class _PillarTile extends StatelessWidget {
  const _PillarTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.termId,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String termId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.info_outline, size: 18),
      onTap: () => HelpSheet.show(context, termId),
    );
  }
}

/// One "how we calculate" block: icon, title, body.
class _MethodBlock extends StatelessWidget {
  const _MethodBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
