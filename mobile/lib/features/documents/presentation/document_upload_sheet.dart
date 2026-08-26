import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/primary_button.dart';
import '../application/documents_providers.dart';
import '../data/document_dtos.dart';
import '../data/document_repository.dart';

/// Upload sheet — ported from iOS's `DocumentUploadSheet`: type (default
/// OTHER), optional year (2000 → current year, current by default),
/// PDF/JPEG/PNG file picker.
///
/// Flutter additions (mission): extension and size check
/// ≤ 10 MB **before reading the file** (in the picker — review 3.8),
/// progress bar (dio onSendProgress), success/
/// error snackbars (the root messenger displays over the sheet). The sheet
/// only closes on success (iOS behavior); if it is closed
/// during the upload, invalidation and the snackbar survive via the
/// container captured before the async gap.
class DocumentUploadSheet extends ConsumerStatefulWidget {
  const DocumentUploadSheet({super.key});

  /// Opens the sheet (`CantonPickerSheet.show` pattern).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const DocumentUploadSheet(),
    );
  }

  @override
  ConsumerState<DocumentUploadSheet> createState() =>
      _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends ConsumerState<DocumentUploadSheet> {
  String _type = 'OTHER';
  bool _includeYear = false;
  int _year = DateTime.now().year;
  bool _uploading = false;
  double? _progress;

  Future<void> _pickAndUpload() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Captured before the async gap: if the sheet is closed during
    // the upload, invalidation and the success snackbar survive
    // (review 3.8 #3) — `ref` on an unmounted State would throw.
    final container = ProviderScope.containerOf(context, listen: false);
    final repository = ref.read(documentRepositoryProvider);

    final picked = await ref.read(documentFilePickerProvider).pick();
    if (!mounted) return;

    // Unusable results: dedicated snackbar (cancelled = silent) —
    // review 3.8 #4. The extension/size checks happened in the
    // picker, BEFORE reading the file (review 3.8 #1).
    final DocumentPickedFile file;
    switch (picked) {
      case DocumentPickCancelled():
        return;
      case DocumentPickInvalidType():
        messenger.showSnackBar(SnackBar(content: Text(l10n.docInvalidFile)));
        return;
      case DocumentPickTooLarge():
        messenger.showSnackBar(SnackBar(content: Text(l10n.docFileTooLarge)));
        return;
      case DocumentPickUnreadable():
        messenger.showSnackBar(SnackBar(content: Text(l10n.docReadError)));
        return;
      case DocumentPickedFile():
        file = picked;
    }

    setState(() {
      _uploading = true;
      _progress = null;
    });
    try {
      // The multipart field order (type, year BEFORE file) is handled
      // by the repository — @fastify/multipart requirement (contract §5).
      await repository.uploadDocument(
        type: _type,
        year: _includeYear ? _year : null,
        filename: file.name,
        bytes: file.bytes,
        onSendProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _progress = sent / total);
          }
        },
      );
      container.invalidate(documentsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.docUploadSuccess)));
      // The sheet only closes on success (iOS behavior) — if it has
      // already been closed during the upload, the pop is skipped but the list
      // is still reloaded and the snackbar shown.
      if (mounted) navigator.pop();
    } on ApiException catch (e) {
      // 402: free limit reached (1 document, contract §11) —
      // localized backend message + action toward the paywall. The router
      // is only resolved if the sheet is still mounted; otherwise the
      // snackbar shows without an action.
      final router = e is PremiumRequiredException && mounted
          ? GoRouter.of(context)
          : null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: router == null
              ? null
              : SnackBarAction(
                  label: l10n.premiumBadgeLabel,
                  onPressed: () => router.push(Routes.paywall),
                ),
        ),
      );
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.docUploadTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.docTypeLabel),
              items: [
                for (final type in documentTypes)
                  DropdownMenuItem(
                    value: type,
                    child: Text(documentTypeLabel(l10n, type)),
                  ),
              ],
              onChanged: _uploading
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(l10n.docIncludeYear),
              contentPadding: EdgeInsets.zero,
              value: _includeYear,
              onChanged: _uploading
                  ? null
                  : (value) => setState(() => _includeYear = value),
            ),
            if (_includeYear) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _year,
                decoration: InputDecoration(labelText: l10n.docYearLabel),
                items: [
                  for (var year = currentYear; year >= 2000; year--)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: _uploading
                    ? null
                    : (value) => setState(() => _year = value ?? _year),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.docChooseFile,
              icon: Icons.upload_file,
              isLoading: _uploading,
              onPressed: _pickAndUpload,
            ),
            if (_uploading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                l10n.docUploading,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
