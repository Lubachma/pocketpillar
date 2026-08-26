import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// User account — `/users/me` endpoint from the contract
/// (`docs/api-contract.md` §6).
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  /// `DELETE /users/me` → 204: deletes the account and all data
  /// (Prisma cascade: profile, LPP/3a accounts, tax situation,
  /// documents) then the Supabase account. GDPR / App Store 5.1.1.
  Future<void> deleteAccount() async {
    await _api.delete<void>('/users/me');
  }
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);
