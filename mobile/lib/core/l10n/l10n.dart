import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// Shorthand access to translations: `context.l10n.tabDashboard`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
