/// Document vault DTOs — contract `docs/api-contract.md` §5,
/// verified against `src/modules/document/document.handler.ts`.
library;

/// Document types, in the backend enum's order (`documentTypeValues`,
/// same order as iOS's `DocumentType.allCases` — display order for the
/// list's sections).
const List<String> documentTypes = [
  'SALARY_SLIP',
  'BVG_STATEMENT',
  'PILLAR3A_STATEMENT',
  'TAX_DECLARATION',
  'OTHER',
];

/// Maximum size client-side (contract §5: 10 MB, backend
/// `MAX_FILE_SIZE`) — checked before any send in the upload sheet.
const int documentMaxSizeBytes = 10 * 1024 * 1024;

/// Accepted extensions (backend MIME: application/pdf, image/jpeg,
/// image/png).
const List<String> documentAllowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

/// Metadata for a document (`GET /documents`, 201 response from
/// `POST /documents`).
class DocumentDto {
  const DocumentDto({
    required this.id,
    required this.type,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.year,
  });

  factory DocumentDto.fromJson(Map<String, dynamic> json) => DocumentDto(
    id: json['id'] as String,
    type: json['type'] as String,
    filename: json['filename'] as String,
    mimeType: json['mimeType'] as String,
    sizeBytes: (json['sizeBytes'] as num).toInt(),
    year: (json['year'] as num?)?.toInt(),
    uploadedAt: DateTime.parse(json['uploadedAt'] as String),
  );

  final String id;
  final String type;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final int? year;
  final DateTime uploadedAt;

  /// Formatted size — rule reused from iOS's `DocumentMeta.formattedSize`:
  /// "%.0f KB" under 1 MB, "%.1f MB" above.
  String get formattedSize {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

/// Response from `GET /documents/:id/download` — signed Supabase URL
/// valid for 300s (no streaming on the backend side).
class DocumentDownloadDto {
  const DocumentDownloadDto({
    required this.url,
    required this.filename,
    required this.mimeType,
  });

  factory DocumentDownloadDto.fromJson(Map<String, dynamic> json) =>
      DocumentDownloadDto(
        url: json['url'] as String,
        filename: json['filename'] as String,
        mimeType: json['mimeType'] as String,
      );

  final String url;
  final String filename;
  final String mimeType;
}
