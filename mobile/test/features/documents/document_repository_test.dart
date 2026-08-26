import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/documents/data/document_repository.dart';

/// Fake HTTP adapter (pattern from `api_client_test.dart`): responds
/// according to [handler] and **captures the real multipart body** to check
/// the field order on the wire (`@fastify/multipart` requirement —
/// contract §5: the `type`/`year` fields before the `file` part).
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<({String method, String path})> calls = [];
  String? lastBody;
  String? lastContentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add((method: options.method, path: options.path));
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in requestStream) {
        builder.add(chunk);
      }
      // latin1: 1 character = 1 byte, safe for a binary body.
      lastBody = latin1.decode(builder.takeBytes());
      lastContentType = options.headers['content-type'] as String?;
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, int statusCode) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Real client wired to the adapter (the error interceptor stays in
/// place — it's what normalizes into [ApiException]).
(ApiClient, _MockAdapter) _harness(
  Future<ResponseBody> Function(RequestOptions) handler,
) {
  final adapter = _MockAdapter(handler);
  final client = ApiClient(
    baseUrl: 'http://localhost:3000',
    dio: Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter,
    getAccessToken: () => 'token',
    refreshAccessToken: () async => null,
    onAuthExpired: () async {},
    getLanguage: () => 'fr',
  );
  return (client, adapter);
}

const _documentJson = <String, dynamic>{
  'id': 'd1',
  'type': 'SALARY_SLIP',
  'filename': 'fiche-salaire.pdf',
  'mimeType': 'application/pdf',
  'sizeBytes': 245760,
  'year': 2025,
  'uploadedAt': '2026-07-01T08:30:00.000Z',
};

void main() {
  test('listDocuments: GET /documents, list parsed (null year tolerated)',
      () async {
    final (client, adapter) = _harness(
      (options) async => _json([
        _documentJson,
        {..._documentJson, 'id': 'd2', 'year': null},
      ], 200),
    );

    final documents = await DocumentRepository(client).listDocuments();

    expect(adapter.calls.single, (method: 'GET', path: '/documents'));
    expect(documents, hasLength(2));
    expect(documents.first.filename, 'fiche-salaire.pdf');
    expect(documents.last.year, isNull);
  });

  test('uploadDocument: type/year fields BEFORE file on the wire', () async {
    final (client, adapter) = _harness(
      (options) async => _json(_documentJson, 201),
    );

    final doc = await DocumentRepository(client).uploadDocument(
      type: 'SALARY_SLIP',
      year: 2025,
      filename: 'fiche.png',
      bytes: Uint8List.fromList(utf8.encode('FAKE-PNG-BYTES')),
    );

    expect(adapter.calls.single, (method: 'POST', path: '/documents'));
    expect(adapter.lastContentType, startsWith('multipart/form-data'));

    final body = adapter.lastBody!;
    final typeIndex = body.indexOf('name="type"');
    final yearIndex = body.indexOf('name="year"');
    final fileIndex = body.indexOf('name="file"');
    expect(typeIndex, greaterThanOrEqualTo(0));
    // Order required by @fastify/multipart: type, year, then file.
    expect(yearIndex, greaterThan(typeIndex));
    expect(fileIndex, greaterThan(yearIndex));
    expect(body, contains('SALARY_SLIP'));
    expect(body, contains('2025'));
    expect(body, contains('filename="fiche.png"'));
    expect(body, contains('FAKE-PNG-BYTES'));

    expect(doc.id, 'd1');
    expect(doc.year, 2025);
  });

  test('uploadDocument without a year: no year field', () async {
    final (client, adapter) = _harness(
      (options) async => _json({..._documentJson, 'year': null}, 201),
    );

    await DocumentRepository(client).uploadDocument(
      type: 'OTHER',
      filename: 'note.pdf',
      bytes: Uint8List.fromList(utf8.encode('PDF')),
    );

    final body = adapter.lastBody!;
    expect(body.indexOf('name="type"'), greaterThanOrEqualTo(0));
    expect(body.contains('name="year"'), isFalse);
    expect(
      body.indexOf('name="file"'),
      greaterThan(body.indexOf('name="type"')),
    );
  });

  test('uploadDocument: 400 propagated (contract message)', () async {
    final (client, _) = _harness(
      (options) async => _json({'error': 'Type de fichier non pris en charge'}, 400),
    );

    await expectLater(
      DocumentRepository(client).uploadDocument(
        type: 'OTHER',
        filename: 'note.pdf',
        bytes: Uint8List(4),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', contains('non pris en charge')),
      ),
    );
  });

  test('uploadDocument: native Fastify 413 propagated', () async {
    // bodyLimit exceeded: native Fastify response, not the unified
    // format (contract §2) — `error` is still read ('Payload Too Large').
    final (client, _) = _harness(
      (options) async => _json({
        'statusCode': 413,
        'code': 'FST_ERR_CTP_BODY_TOO_LARGE',
        'error': 'Payload Too Large',
        'message': 'Request body is too large',
      }, 413),
    );

    await expectLater(
      DocumentRepository(client).uploadDocument(
        type: 'OTHER',
        filename: 'gros.pdf',
        bytes: Uint8List(4),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 413)
            .having((e) => e.message, 'message', 'Payload Too Large'),
      ),
    );
  });

  test('getDownloadUrl: GET /documents/:id/download, response parsed',
      () async {
    final (client, adapter) = _harness(
      (options) async => _json({
        'url': 'https://storage.supabase.co/sign/abc?token=xyz',
        'filename': 'fiche-salaire.pdf',
        'mimeType': 'application/pdf',
      }, 200),
    );

    final download = await DocumentRepository(client).getDownloadUrl('d1');

    expect(
      adapter.calls.single,
      (method: 'GET', path: '/documents/d1/download'),
    );
    expect(download.url, contains('token=xyz'));
  });

  test('deleteDocument: DELETE /documents/:id (204)', () async {
    final (client, adapter) = _harness(
      (options) async => ResponseBody.fromString('', 204),
    );

    await DocumentRepository(client).deleteDocument('d1');

    expect(adapter.calls.single, (method: 'DELETE', path: '/documents/d1'));
  });

  test('deleteDocument: 404 propagated', () async {
    final (client, _) = _harness(
      (options) async => _json({'error': 'Document introuvable'}, 404),
    );

    await expectLater(
      DocumentRepository(client).deleteDocument('inconnu'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });
}
