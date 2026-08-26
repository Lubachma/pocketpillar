import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/documents/data/document_dtos.dart';

void main() {
  group('DocumentDto', () {
    test('parses a complete backend response', () {
      // Fixture modeled on the response from `listDocumentsHandler` /
      // `uploadDocumentHandler` (`src/modules/document/document.handler.ts`).
      final doc = DocumentDto.fromJson(const {
        'id': 'd1',
        'type': 'SALARY_SLIP',
        'filename': 'fiche-salaire.pdf',
        'mimeType': 'application/pdf',
        'sizeBytes': 245760,
        'year': 2025,
        'uploadedAt': '2026-07-01T08:30:00.000Z',
      });

      expect(doc.id, 'd1');
      expect(doc.type, 'SALARY_SLIP');
      expect(doc.filename, 'fiche-salaire.pdf');
      expect(doc.mimeType, 'application/pdf');
      expect(doc.sizeBytes, 245760);
      expect(doc.year, 2025);
      expect(doc.uploadedAt, DateTime.utc(2026, 7, 1, 8, 30));
    });

    test('null year tolerated (optional schema field)', () {
      final doc = DocumentDto.fromJson(const {
        'id': 'd2',
        'type': 'OTHER',
        'filename': 'note.png',
        'mimeType': 'image/png',
        'sizeBytes': 512,
        'year': null,
        'uploadedAt': '2026-07-01T08:30:00.000Z',
      });

      expect(doc.year, isNull);
    });

    test('formatted size: iOS rule (integer KB < 1 MB, otherwise MB ×0.1)', () {
      DocumentDto sized(int bytes) => DocumentDto(
        id: 'd',
        type: 'OTHER',
        filename: 'f',
        mimeType: 'application/pdf',
        sizeBytes: bytes,
        uploadedAt: DateTime.utc(2026),
      );

      expect(sized(0).formattedSize, '0 KB');
      expect(sized(2048).formattedSize, '2 KB');
      expect(sized(1023 * 1024).formattedSize, '1023 KB');
      expect(sized(1024 * 1024).formattedSize, '1.0 MB');
      expect(sized(1572864).formattedSize, '1.5 MB');
    });
  });

  group('DocumentDownloadDto', () {
    test('parses the signed URL response', () {
      final download = DocumentDownloadDto.fromJson(const {
        'url': 'https://storage.supabase.co/documents/sign/abc?token=xyz',
        'filename': 'fiche-salaire.pdf',
        'mimeType': 'application/pdf',
      });

      expect(download.url, contains('token=xyz'));
      expect(download.filename, 'fiche-salaire.pdf');
      expect(download.mimeType, 'application/pdf');
    });
  });
}
