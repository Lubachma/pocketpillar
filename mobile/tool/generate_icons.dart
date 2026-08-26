// Génère les sources PNG de l'icône d'app et du splash (1024×1024) :
//
//  - `assets/icon/icon.png`            icône plein cadre (iOS + Android legacy)
//  - `assets/icon/icon_foreground.png` fond transparent, plaque quasi plein
//    cadre (l'inset 16 % de flutter_launcher_icons la ramène dans le masque
//    circulaire des icônes adaptatives Android)
//  - `assets/icon/icon_splash.png`     logo centré du splash (fond transparent)
//
// Usage (depuis `mobile/`) :
//
// ```bash
// dart run tool/generate_icons.dart
// dart run flutter_launcher_icons    # régénère les icônes natives
// dart run flutter_native_splash:create   # régénère les splash natifs
// ```
//
// Design : fond bleu #007AFF (couleur primaire, `AppColors.accent`), plaque
// blanche arrondie, 3 barres « piliers » ascendantes aux couleurs exactes du
// thème (`AppColors.pillar1/pillar2/pillar3a`). La plaque blanche évite la
// collision bleu-sur-bleu de la barre du pilier 2 (#007AFF sur fond #007AFF).
// Rendu en supersampling ×4 puis réduction (anti-aliasing propre).
import 'dart:io';

import 'package:image/image.dart' as img;

// Palette exacte de lib/core/theme/app_colors.dart.
const _pillar1 = 0xFF00C7BE;
const _pillar2 = 0xFF007AFF;
const _pillar3a = 0xFFAF52DE;
const _accent = 0xFF007AFF;
const _white = 0xFFFFFFFF;

const _scale = 4; // supersampling
const _size = 1024;

img.ColorRgb8 _rgb(int argb) => img.ColorRgb8(
  (argb >> 16) & 0xFF,
  (argb >> 8) & 0xFF,
  argb & 0xFF,
);

/// Trois barres « piliers » à extrémités arrondies, hauteurs ascendantes,
/// alignées sur une ligne de base commune. Coordonnées en unités du canvas
/// 1024 (le dessin est supersamplé ×[_scale]).
void _drawPillarBars(
  img.Image dst, {
  required double groupWidth,
  required List<double> heights,
  required double baseY,
}) {
  const colors = [_pillar1, _pillar2, _pillar3a];
  final barW = groupWidth * 0.238;
  final gap = (groupWidth - 3 * barW) / 2;
  final startX = _size / 2 - groupWidth / 2;
  for (var i = 0; i < 3; i++) {
    img.fillRect(
      dst,
      x1: ((startX + i * (barW + gap)) * _scale).round(),
      y1: ((baseY - heights[i]) * _scale).round(),
      x2: ((startX + i * (barW + gap) + barW) * _scale).round(),
      y2: (baseY * _scale).round(),
      color: _rgb(colors[i]),
      radius: barW * _scale / 2,
    );
  }
}

/// Plaque blanche arrondie centrée, côté [plateSize], + les 3 barres.
/// [barScale] dimensionne le groupe de barres par rapport à la plaque.
void _drawMark(
  img.Image dst, {
  required double plateSize,
  required double groupWidth,
  required List<double> heights,
}) {
  final plateX = (_size - plateSize) / 2;
  final innerPad = (plateSize - groupWidth) / 2;
  img.fillRect(
    dst,
    x1: (plateX * _scale).round(),
    y1: (plateX * _scale).round(),
    x2: ((plateX + plateSize) * _scale).round(),
    y2: ((plateX + plateSize) * _scale).round(),
    color: _rgb(_white),
    radius: plateSize * 0.214 * _scale,
  );
  _drawPillarBars(
    dst,
    groupWidth: groupWidth,
    heights: heights,
    baseY: plateX + plateSize - innerPad,
  );
}

img.Image _filledCanvas(int argb) {
  final im = img.Image(width: _size * _scale, height: _size * _scale);
  img.fillRect(
    im,
    x1: 0,
    y1: 0,
    x2: im.width - 1,
    y2: im.height - 1,
    color: _rgb(argb),
  );
  return im;
}

img.Image _transparentCanvas() =>
    img.Image(width: _size * _scale, height: _size * _scale, numChannels: 4);

void _save(img.Image im, String path) {
  final small = img.copyResize(
    im,
    width: _size,
    height: _size,
    interpolation: img.Interpolation.average,
  );
  File(path).writeAsBytesSync(img.encodePng(small));
  stdout.writeln('écrit: $path');
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Icône plein cadre : plaque 700 px, barres 380/480/580.
  final icon = _filledCanvas(_accent);
  _drawMark(icon, plateSize: 700, groupWidth: 546, heights: [380, 480, 580]);
  _save(icon, 'assets/icon/icon.png');

  // Foreground adaptatif : plaque 920 px — flutter_launcher_icons applique
  // un inset de 16 % au runtime (ic_launcher.xml), donc la plaque affichée
  // fait ~61 % du canvas : dans le masque circulaire (rayon 50 %) et
  // généreuse en présence, coins éventuellement rognés sur les masques OEM
  // agressifs (rendu cohérent : plaque blanche sur fond bleu).
  final foreground = _transparentCanvas();
  _drawMark(
    foreground,
    plateSize: 920,
    groupWidth: 736,
    heights: [490, 613, 736],
  );
  _save(foreground, 'assets/icon/icon_foreground.png');

  // Logo de splash : plaque 640 px.
  final splash = _transparentCanvas();
  _drawMark(splash, plateSize: 640, groupWidth: 512, heights: [340, 425, 510]);
  _save(splash, 'assets/icon/icon_splash.png');
}
