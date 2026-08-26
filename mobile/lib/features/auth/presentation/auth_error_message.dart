import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../application/auth_service.dart';

/// Translates an authentication error into a displayable localized message.
///
/// Takes `l10n` (captured before any `await`) rather than a [BuildContext]
/// to avoid using context across an async gap.
///
/// [authFailure] is the fallback for Supabase [AuthException]s (whose
/// messages are in English): sign-in or account creation failure.
String authErrorMessage(
  AppLocalizations l10n,
  Object error, {
  required String authFailure,
}) {
  return switch (error) {
    EmailAlreadyTakenException() => l10n.authEmailTaken,
    AuthException() => authFailure,
    ApiException() => error.message,
    NetworkException() => l10n.errorNetwork,
    _ => l10n.errorUnknown,
  };
}
