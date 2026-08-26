import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/utils/native_file_io.dart';
import '../data/document_dtos.dart';
import '../data/document_repository.dart';

/// List of documents (`GET /documents`). Pull-to-refresh / retry:
/// `ref.invalidate(documentsProvider)`.
final documentsProvider = FutureProvider<List<DocumentDto>>(
  (ref) => ref.watch(documentRepositoryProvider).listDocuments(),
);

/// Result of a file selection — distinguished so the sheet
/// shows the right snackbar (review 3.8 #4: cancelled = silent,
/// unreadable = error).
sealed class DocumentPickResult {
  const DocumentPickResult();
}

/// Pick cancelled by the user — silent.
final class DocumentPickCancelled extends DocumentPickResult {
  const DocumentPickCancelled();
}

/// Extension outside the allowed list (pdf/jpg/jpeg/png — contract §5).
final class DocumentPickInvalidType extends DocumentPickResult {
  const DocumentPickInvalidType();
}

/// File > 10 MB (contract §5) — detected BEFORE reading into RAM.
final class DocumentPickTooLarge extends DocumentPickResult {
  const DocumentPickTooLarge();
}

/// Unreadable data (no path, read failure) after a successful
/// pick — error snackbar, not silence.
final class DocumentPickUnreadable extends DocumentPickResult {
  const DocumentPickUnreadable();
}

/// File chosen, checked and read — ready for upload.
final class DocumentPickedFile extends DocumentPickResult {
  const DocumentPickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Abstraction over the file picker (platform channel
/// `file_picker`) — swappable in tests via
/// [documentFilePickerProvider].
abstract class DocumentFilePicker {
  Future<DocumentPickResult> pick();
}

class FilePickerDocumentFilePicker implements DocumentFilePicker {
  @override
  Future<DocumentPickResult> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: documentAllowedExtensions,
      // Web: no path — bytes are read by the plugin (withData
      // required). Elsewhere, no withData: loading the whole file into
      // RAM BEFORE the 10 MB guard would risk an OOM (review 3.8 #1).
      withData: kIsWeb,
    );
    final file = result?.files.single;
    if (file == null) return const DocumentPickCancelled();

    final extension = file.extension?.toLowerCase() ?? '';
    if (!documentAllowedExtensions.contains(extension)) {
      return const DocumentPickInvalidType();
    }
    // Size guard on the metadata, BEFORE any reading.
    if (file.size > documentMaxSizeBytes) {
      return const DocumentPickTooLarge();
    }
    try {
      // Native: read via the path (null if missing → "unreadable",
      // unchanged behavior). Web: bytes already in memory (withData).
      final bytes = await readPickedFileBytes(file);
      if (bytes == null) return const DocumentPickUnreadable();
      // Belt and braces: the size reported by the picker can
      // be misleading — re-check after reading.
      if (bytes.length > documentMaxSizeBytes) {
        return const DocumentPickTooLarge();
      }
      return DocumentPickedFile(name: file.name, bytes: bytes);
    } on Object {
      return const DocumentPickUnreadable();
    }
  }
}

final documentFilePickerProvider = Provider<DocumentFilePicker>(
  (ref) => FilePickerDocumentFilePicker(),
);

/// Localized label for a document type (`docType*` keys migrated).
String documentTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'SALARY_SLIP' => l10n.docTypeSalarySlip,
    'BVG_STATEMENT' => l10n.docTypeBvgStatement,
    'PILLAR3A_STATEMENT' => l10n.docTypePillar3aStatement,
    'TAX_DECLARATION' => l10n.docTypeTaxDeclaration,
    _ => l10n.docTypeOther,
  };
}
