import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/swiss_canton.dart';
import '../../utils/text_normalization.dart';

/// Canton picker sheet — ported from `Shared/CantonPicker.swift`:
/// 26 cantons grouped by region, search (name or code, accent
/// insensitive), checkmark on the selected canton.
///
/// Returns the canton code (`VD`, `ZH`, ...) via `Navigator.pop`, or
/// null if closed without a choice.
class CantonPickerSheet extends StatefulWidget {
  const CantonPickerSheet({this.selectedCode, super.key});

  final String? selectedCode;

  /// Opens the sheet and waits for the chosen code (null if cancelled).
  static Future<String?> show(BuildContext context, {String? selectedCode}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CantonPickerSheet(selectedCode: selectedCode),
    );
  }

  @override
  State<CantonPickerSheet> createState() => _CantonPickerSheetState();
}

class _CantonPickerSheetState extends State<CantonPickerSheet> {
  String _query = '';

  /// Lowercase without diacritics — see [normalizeDiacritics] (shared
  /// with the municipality picker).
  static String _normalize(String value) => normalizeDiacritics(value);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final query = _normalize(_query.trim());

    final groups = [
      for (final (region, cantons) in groupedSwissCantons(languageCode))
        if (query.isEmpty)
          (region, cantons)
        else
          (
            region,
            cantons
                .where(
                  (c) =>
                      _normalize(c.localizedName(languageCode))
                          .contains(query) ||
                      c.code.toLowerCase().contains(query),
                )
                .toList(),
          ),
    ];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                labelText: l10n.cantonPickerSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final (region, cantons) in groups)
                  if (cantons.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        cantonRegionName(region, languageCode),
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    for (final canton in cantons)
                      ListTile(
                        title: Text(canton.displayName(languageCode)),
                        trailing: canton.code == widget.selectedCode
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(canton.code),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
