import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import 'document_dtos.dart';

/// Document vault repository — authenticated `/documents*`
/// endpoints (contract §5, routes verified against
/// `src/modules/document/document.routes.ts`).
///
/// iOS went through Supabase directly (table + storage); Flutter goes
/// through the backend — which **fixes iOS's broken deletion**
/// (`storagePath: ""` on iOS: the Storage file survived and the
/// DB row was never erased; the backend knows the real
/// `storagePath` and deletes the file **then** the row).
class DocumentRepository {
  DocumentRepository(this._api);

  final ApiClient _api;

  /// List of the user's documents, sorted by upload date
  /// descending (backend order). Grouping by type is done
  /// client-side (like iOS) — the `type` query is not used.
  Future<List<DocumentDto>> listDocuments() async {
    final response = await _api.get('/documents');
    return [
      for (final item in response.data as List<dynamic>)
        DocumentDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Multipart upload (`POST /documents`, rate-limit 20/min).
  ///
  /// **Field order required** (contract §5): `@fastify/multipart` only
  /// populates `data.fields` with fields received BEFORE the file
  /// part — `type`, then `year` (optional), then `file`. dio
  /// serializes a [FormData]'s fields before the files by
  /// construction; the insertion order below fixes the field order.
  ///
  /// Goes through `ApiClient.raw` (exposed for multipart, phase 0):
  /// the interceptor already normalizes errors, so we simply unwrap
  /// `DioException.error` the way `ApiClient._guard` does.
  Future<DocumentDto> uploadDocument({
    required String type,
    required String filename,
    required Uint8List bytes,
    int? year,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData()..fields.add(MapEntry('type', type));
    if (year != null) formData.fields.add(MapEntry('year', '$year'));
    // The part's content-type is inferred from the filename's
    // extension (pdf/jpeg/png — extensions already filtered by the picker).
    formData.files.add(
      MapEntry('file', MultipartFile.fromBytes(bytes, filename: filename)),
    );
    try {
      final response = await _api.raw.post<dynamic>(
        '/documents',
        data: formData,
        onSendProgress: onSendProgress,
      );
      return DocumentDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      if (error is NetworkException) throw error;
      throw NetworkException(e.message ?? 'Erreur réseau');
    }
  }

  /// Signed download URL (`GET /documents/:id/download`,
  /// valid for 300s). 404 → [ApiException] propagated (the screen shows the
  /// message).
  Future<DocumentDownloadDto> getDownloadUrl(String id) async {
    final response = await _api.get('/documents/$id/download');
    return DocumentDownloadDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deletion (`DELETE /documents/:id` → 204): the backend deletes
  /// the Storage file then the row — deletion actually
  /// works, unlike iOS (see the class header).
  Future<void> deleteDocument(String id) async {
    await _api.delete('/documents/$id');
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(ref.watch(apiClientProvider)),
);
