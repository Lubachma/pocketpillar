/// Normalization for search: lowercase without diacritics
/// (e.g. "e" with an accent becomes a plain "e"), so pickers (canton,
/// municipality) ignore accents — the displayed names stay accented.
library;

String normalizeDiacritics(String value) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
  };
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final unit in lower.codeUnits) {
    final char = String.fromCharCode(unit);
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString();
}
