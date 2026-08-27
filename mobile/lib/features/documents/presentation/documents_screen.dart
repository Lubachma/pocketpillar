import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../application/documents_providers.dart';
import '../data/document_dtos.dart';
import '../data/document_repository.dart';
import 'document_upload_sheet.dart';

/// Document vault — ported from iOS's `DocumentsView` (phase 3.8).
///
/// - List grouped by type (5 types, iOS enum order), dedicated
///   loading / error-with-retry / empty states, pull-to-refresh.
/// - Tapping a row → opens via a signed URL
///   (`GET /documents/:id/download` + `url_launcher`) — iOS had
///   no opening at all.
/// - Swipe deletion **with confirmation** (Flutter addition,
///   mission) → `DELETE /documents/:id` via the backend: deletion
///   actually works, unlike iOS (empty `storagePath` —
///   known platform pitfalls).
/// - Upload via [DocumentUploadSheet] ("+" button in the appbar).
///
/// Not ported: the anti-screenshot protection (iOS's `SecureView`)
/// — no off-the-shelf Flutter equivalent.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  /// Document currently being opened (spinner on the row).
  String? _openingId;

  Future<void> _open(DocumentDto doc) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _openingId = doc.id);
    try {
      final download = await ref
          .read(documentRepositoryProvider)
          .getDownloadUrl(doc.id);
      // Pattern reused from provider_detail_screen.dart: try/catch +
      // false return from launchUrl, never a silent failure.
      final launched = await launchUrl(
        Uri.parse(download.url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('launchUrl returned false');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    } on Object {
      // Malformed URL or platform channel unavailable.
      messenger.showSnackBar(SnackBar(content: Text(l10n.docOpenError)));
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  /// Confirmation → DELETE → removal from the list (via invalidation).
  /// The swipe is always cancelled (`false`): the row disappears when
  /// the reloaded list no longer contains the document.
  Future<bool> _confirmDelete(DocumentDto doc) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.docDeleteConfirmTitle),
        content: Text(l10n.docDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.authCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.docDelete,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    try {
      await ref.read(documentRepositoryProvider).deleteDocument(doc.id);
      if (!mounted) return false;
      ref.invalidate(documentsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.docDeleted)));
    } on ApiException catch (e) {
      // 404: the document no longer exists server-side — resynchronize
      // the list to remove it from the UI (review 3.8 #2).
      if (e.statusCode == 404 && mounted) ref.invalidate(documentsProvider);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    }
    return false;
  }

  Future<void> _onRefresh() async {
    ref.invalidate(documentsProvider);
    try {
      await ref.read(documentsProvider.future);
    } on Object {
      // Error state shown by the screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.docTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.docUploadTitle,
            onPressed: () => DocumentUploadSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: documents.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 420,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, _) => _DocumentsError(error: error),
          data: (docs) => docs.isEmpty
              ? const _DocumentsEmpty()
              : _DocumentsList(
                  documents: docs,
                  openingId: _openingId,
                  onOpen: _open,
                  onDelete: _confirmDelete,
                ),
        ),
      ),
    );
  }
}

class _DocumentsEmpty extends StatelessWidget {
  const _DocumentsEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(l10n.docEmptyTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.docEmptyDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentsError extends ConsumerWidget {
  const _DocumentsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final message = switch (error) {
      ApiException(:final message) => message,
      NetworkException() => l10n.errorNetwork,
      _ => l10n.errorNetwork,
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.commonRetry,
                    onPressed: () => ref.invalidate(documentsProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// List grouped by type (sections in enum order, like iOS's
/// `Dictionary(grouping:)` + `DocumentType.allCases`).
class _DocumentsList extends StatelessWidget {
  const _DocumentsList({
    required this.documents,
    required this.openingId,
    required this.onOpen,
    required this.onDelete,
  });

  final List<DocumentDto> documents;
  final String? openingId;
  final ValueChanged<DocumentDto> onOpen;
  final Future<bool> Function(DocumentDto) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final grouped = <String, List<DocumentDto>>{
      for (final type in documentTypes)
        type: [
          for (final doc in documents)
            if (doc.type == type) doc,
        ],
    };
    final presentTypes = [
      for (final type in documentTypes)
        if (grouped[type]!.isNotEmpty) type,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final type in presentTypes) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              documentTypeLabel(l10n, type),
              style: theme.textTheme.titleSmall,
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final doc in grouped[type]!)
                  _DocumentTile(
                    document: doc,
                    opening: doc.id == openingId,
                    onOpen: onOpen,
                    onDelete: onDelete,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

/// Document row — ported from iOS's `DocumentRowView` (icon by type,
/// name, size · year · date), with tap-to-open and swipe deletion
/// (confirmed).
class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.opening,
    required this.onOpen,
    required this.onDelete,
  });

  final DocumentDto document;
  final bool opening;
  final ValueChanged<DocumentDto> onOpen;
  final Future<bool> Function(DocumentDto) onDelete;

  /// Mapping from iOS's SF Symbols (`DocumentType.icon`) to Material.
  IconData get _icon {
    return switch (document.type) {
      'SALARY_SLIP' => Icons.payments_outlined,
      'BVG_STATEMENT' => Icons.account_balance_outlined,
      'PILLAR3A_STATEMENT' => Icons.trending_up,
      'TAX_DECLARATION' => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final subtitle = StringBuffer(document.formattedSize);
    if (document.year != null) subtitle.write(' · ${document.year}');
    subtitle.write(
      ' · ${DateFormat.yMMMd(locale).format(document.uploadedAt)}',
    );

    return Dismissible(
      key: ValueKey(document.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(document),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: ListTile(
        leading: Icon(_icon, color: theme.colorScheme.primary),
        title: Text(
          document.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle.toString()),
        trailing: opening
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: () => onOpen(document),
      ),
    );
  }
}
