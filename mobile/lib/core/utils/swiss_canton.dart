/// The 26 Swiss cantons — ported from
/// `ios/PocketPillar/Models/SwissCanton.swift` (same codes, same fr/de/en
/// names, same regions).
library;

/// Grouping region for the picker (display order = enum order).
enum CantonRegion { romandie, deutschschweiz, ticino }

class SwissCanton {
  const SwissCanton({
    required this.code,
    required this.nameFr,
    required this.nameDe,
    required this.nameEn,
    required this.region,
  });

  /// 2-letter uppercase code (`ZH`, `VD`, ...) — value sent to the API.
  final String code;
  final String nameFr;
  final String nameDe;
  final String nameEn;
  final CantonRegion region;

  /// Localized name based on the language code (`fr` by default).
  String localizedName(String languageCode) => switch (languageCode) {
    'de' => nameDe,
    'en' => nameEn,
    _ => nameFr,
  };

  /// "Vaud (VD)" — the iOS display format.
  String displayName(String languageCode) =>
      '${localizedName(languageCode)} ($code)';
}

/// Localized label for a region (picker section headers).
String cantonRegionName(CantonRegion region, String languageCode) =>
    switch ((region, languageCode)) {
      (CantonRegion.romandie, 'de') => 'Westschweiz',
      (CantonRegion.romandie, 'en') => 'Western Switzerland',
      (CantonRegion.romandie, _) => 'Romandie',
      (CantonRegion.deutschschweiz, 'fr') => 'Suisse alémanique',
      (CantonRegion.deutschschweiz, 'en') => 'German-speaking Switzerland',
      (CantonRegion.deutschschweiz, _) => 'Deutschschweiz',
      (CantonRegion.ticino, 'fr') => 'Tessin',
      (CantonRegion.ticino, 'en') => 'Ticino',
      (CantonRegion.ticino, _) => 'Tessin',
    };

const List<SwissCanton> swissCantons = [
  // Romandie
  SwissCanton(
    code: 'GE',
    nameFr: 'Genève',
    nameDe: 'Genf',
    nameEn: 'Geneva',
    region: CantonRegion.romandie,
  ),
  SwissCanton(
    code: 'VD',
    nameFr: 'Vaud',
    nameDe: 'Waadt',
    nameEn: 'Vaud',
    region: CantonRegion.romandie,
  ),
  SwissCanton(
    code: 'VS',
    nameFr: 'Valais',
    nameDe: 'Wallis',
    nameEn: 'Valais',
    region: CantonRegion.romandie,
  ),
  SwissCanton(
    code: 'NE',
    nameFr: 'Neuchâtel',
    nameDe: 'Neuenburg',
    nameEn: 'Neuchatel',
    region: CantonRegion.romandie,
  ),
  SwissCanton(
    code: 'FR',
    nameFr: 'Fribourg',
    nameDe: 'Freiburg',
    nameEn: 'Fribourg',
    region: CantonRegion.romandie,
  ),
  SwissCanton(
    code: 'JU',
    nameFr: 'Jura',
    nameDe: 'Jura',
    nameEn: 'Jura',
    region: CantonRegion.romandie,
  ),
  // Deutschschweiz
  SwissCanton(
    code: 'ZH',
    nameFr: 'Zurich',
    nameDe: 'Zürich',
    nameEn: 'Zurich',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'BE',
    nameFr: 'Berne',
    nameDe: 'Bern',
    nameEn: 'Bern',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'LU',
    nameFr: 'Lucerne',
    nameDe: 'Luzern',
    nameEn: 'Lucerne',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'UR',
    nameFr: 'Uri',
    nameDe: 'Uri',
    nameEn: 'Uri',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'SZ',
    nameFr: 'Schwyz',
    nameDe: 'Schwyz',
    nameEn: 'Schwyz',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'OW',
    nameFr: 'Obwald',
    nameDe: 'Obwalden',
    nameEn: 'Obwalden',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'NW',
    nameFr: 'Nidwald',
    nameDe: 'Nidwalden',
    nameEn: 'Nidwalden',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'GL',
    nameFr: 'Glaris',
    nameDe: 'Glarus',
    nameEn: 'Glarus',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'ZG',
    nameFr: 'Zoug',
    nameDe: 'Zug',
    nameEn: 'Zug',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'SO',
    nameFr: 'Soleure',
    nameDe: 'Solothurn',
    nameEn: 'Solothurn',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'BS',
    nameFr: 'Bâle-Ville',
    nameDe: 'Basel-Stadt',
    nameEn: 'Basel-City',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'BL',
    nameFr: 'Bâle-Campagne',
    nameDe: 'Basel-Landschaft',
    nameEn: 'Basel-Country',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'SH',
    nameFr: 'Schaffhouse',
    nameDe: 'Schaffhausen',
    nameEn: 'Schaffhausen',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'AR',
    nameFr: 'Appenzell Rh.-Ext.',
    nameDe: 'Appenzell Ausserrhoden',
    nameEn: 'Appenzell Outer Rhodes',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'AI',
    nameFr: 'Appenzell Rh.-Int.',
    nameDe: 'Appenzell Innerrhoden',
    nameEn: 'Appenzell Inner Rhodes',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'SG',
    nameFr: 'Saint-Gall',
    nameDe: 'St. Gallen',
    nameEn: 'St. Gallen',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'GR',
    nameFr: 'Grisons',
    nameDe: 'Graubünden',
    nameEn: 'Graubunden',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'AG',
    nameFr: 'Argovie',
    nameDe: 'Aargau',
    nameEn: 'Aargau',
    region: CantonRegion.deutschschweiz,
  ),
  SwissCanton(
    code: 'TG',
    nameFr: 'Thurgovie',
    nameDe: 'Thurgau',
    nameEn: 'Thurgau',
    region: CantonRegion.deutschschweiz,
  ),
  // Ticino
  SwissCanton(
    code: 'TI',
    nameFr: 'Tessin',
    nameDe: 'Tessin',
    nameEn: 'Ticino',
    region: CantonRegion.ticino,
  ),
];

/// Finds a canton by its code (`VD` → Vaud), `null` if unknown.
SwissCanton? findSwissCanton(String? code) {
  if (code == null) return null;
  for (final canton in swissCantons) {
    if (canton.code == code) return canton;
  }
  return null;
}

/// Cantons grouped by region, sorted by localized name (like iOS's
/// `SwissCantons.grouped(locale:)`).
List<(CantonRegion, List<SwissCanton>)> groupedSwissCantons(
  String languageCode,
) {
  return [
    for (final region in CantonRegion.values)
      (
        region,
        swissCantons.where((c) => c.region == region).toList()..sort(
          (a, b) => a
              .localizedName(languageCode)
              .compareTo(b.localizedName(languageCode)),
        ),
      ),
  ];
}
