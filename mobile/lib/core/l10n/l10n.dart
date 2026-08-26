import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// Raccourci d'accès aux traductions : `context.l10n.tabDashboard`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
