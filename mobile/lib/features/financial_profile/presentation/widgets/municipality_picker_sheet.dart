import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/text_normalization.dart';
import '../../data/financial_profile_repository.dart';
import '../../data/municipality.dart';

/// Value returned by [MunicipalityPickerSheet.show] when the "cantonal
/// average" option is chosen — distinguishes an **explicit
/// deselection** from closing without a choice (null). Empty string:
/// never a valid municipality name (the backend enforces 1–100
/// characters).
const String municipalityCantonalAverageSentinel = '';

/// Municipality picker sheet — same pattern as [CantonPickerSheet]:
/// accent-insensitive search, checkmark on the selection. Municipalities
/// are loaded from `GET /calculator/municipalities?canton=…` (loading,
/// error + retry, empty state when the canton has no covered
/// municipality).
///
/// Returns via `Navigator.pop` the municipality name, or
/// [municipalityCantonalAverageSentinel] for the "cantonal average"
/// option; null = sheet closed without a choice (callers then keep
/// the current selection).
class MunicipalityPickerSheet extends ConsumerStatefulWidget {
  const MunicipalityPickerSheet({
    required this.cantonCode,
    this.selectedName,
    super.key,
  });

  /// 2-letter canton code (`ZH`, `VD`, …) — the list depends on the canton.
  final String cantonCode;

  final String? selectedName;

  /// Opens the sheet and awaits the choice: municipality name,
  /// [municipalityCantonalAverageSentinel] for "cantonal average",
  /// null if closed without a choice.
  static Future<String?> show(
    BuildContext context, {
    required String cantonCode,
    String? selectedName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MunicipalityPickerSheet(
        cantonCode: cantonCode,
        selectedName: selectedName,
      ),
    );
  }

  @override
  ConsumerState<MunicipalityPickerSheet> createState() =>
      _MunicipalityPickerSheetState();
}

class _MunicipalityPickerSheetState
    extends ConsumerState<MunicipalityPickerSheet> {
  String _query = '';

  /// Loaded municipalities — null while loading hasn't completed
  /// (in progress or failed, distinguished by [_error]).
  List<MunicipalityInfo>? _municipalities;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ref
          .read(financialProfileRepositoryProvider)
          .fetchMunicipalities(widget.cantonCode);
      if (!mounted) return;
      setState(() {
        _municipalities = list;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _municipalities = null;
        _error = e;
      });
    }
  }

  void _retry() {
    setState(() {
      _municipalities = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = normalizeDiacritics(_query.trim());
    final municipalities = _municipalities;
    final filtered = municipalities == null || query.isEmpty
        ? municipalities
        : [
            for (final municipality in municipalities)
              if (normalizeDiacritics(municipality.name).contains(query))
                municipality,
          ];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.municipalityPickerTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                labelText: l10n.municipalityPickerSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(child: _buildBody(filtered)),
        ],
      ),
    );
  }

  Widget _buildBody(List<MunicipalityInfo>? filtered) {
    final l10n = context.l10n;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.municipalityPickerError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _retry, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      );
    }
    if (filtered == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Lazy list (full review 2026-08): cantons have up to several
    // hundred municipalities.
    return ListView.builder(
      itemCount: filtered.isEmpty ? 2 : 2 + filtered.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Explicit deselection: falls back to the cantonal average
          // (what the calculator applies without a municipality, or
          // for an uncovered municipality).
          return ListTile(
            title: Text(l10n.municipalityCantonalAverageOption),
            trailing: widget.selectedName == null
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () =>
                Navigator.of(context).pop(municipalityCantonalAverageSentinel),
          );
        }
        if (index == 1) {
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                // Canton with no covered municipality ≠ search with no results.
                (_municipalities ?? const []).isEmpty
                    ? l10n.municipalityPickerEmpty
                    : l10n.municipalityPickerNoResults,
                textAlign: TextAlign.center,
              ),
            );
          }
          return const Divider(height: 1);
        }
        final municipality = filtered[index - 2];
        return ListTile(
          title: Text(municipality.name),
          trailing: municipality.name == widget.selectedName
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => Navigator.of(context).pop(municipality.name),
        );
      },
    );
  }
}
