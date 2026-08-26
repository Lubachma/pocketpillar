/// Swiss municipality covered by the tax calculator — element of
/// `GET /calculator/municipalities?canton=…` (public endpoint, shape
/// verified against `src/modules/calculator/`).
///
/// The actual municipal tax multiplier (2026) is kept for debugging
/// and future use — the UI only displays the name.
library;

class MunicipalityInfo {
  const MunicipalityInfo({required this.name, required this.multiplier});

  /// Official name of the municipality (e.g. `Adliswil`).
  final String name;

  /// Municipal tax multiplier in percent (e.g. `104` = 104%).
  final double multiplier;

  factory MunicipalityInfo.fromJson(Map<String, dynamic> json) =>
      MunicipalityInfo(
        name: json['name'] as String,
        multiplier: (json['multiplier'] as num).toDouble(),
      );
}
