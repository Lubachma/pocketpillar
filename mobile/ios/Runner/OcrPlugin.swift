import Flutter
import UIKit
import Vision

/// Plugin OCR iOS — reconnaissance de texte **on-device** via Apple Vision
/// (`VNRecognizeTextRequest`).
///
/// Remplace `google_mlkit_text_recognition`, dont les binaires n'ont pas de
/// slice arm64 pour le simulateur (et iOS 26 n'exécute plus de x86_64 :
/// simulateur inutilisable). Vision est un framework système : aucun pod,
/// arm64 simulateur natif, cible iOS 13+ suffisante.
///
/// Contrat du channel `ch.pocketpillar.app/ocr` (identique à l'implémentation
/// Android, qui elle reste sur ML Kit — voir `OcrPlugin.kt`) :
/// - méthode `recognizeText`, argument `imagePath` (String) ;
/// - retour : le texte brut, lignes jointes par `\n` (le parsing métier
///   reste côté Dart) ;
/// - erreurs : `bad_args`, `file_not_found`, `invalid_image`, `vision_error`.
class OcrPlugin: NSObject, FlutterPlugin {
  static let channelName = "ch.pocketpillar.app/ocr"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = OcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeText" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String else {
      result(FlutterError(
        code: "bad_args",
        message: "Argument « imagePath » (String) attendu.",
        details: nil
      ))
      return
    }
    recognizeText(imagePath: imagePath, result: result)
  }

  private func recognizeText(imagePath: String, result: @escaping FlutterResult) {
    guard FileManager.default.fileExists(atPath: imagePath) else {
      result(FlutterError(
        code: "file_not_found",
        message: "Fichier introuvable : \(imagePath)",
        details: nil
      ))
      return
    }
    // Validation à moindre coût (le décodage pixel est paresseux) pour
    // distinguer « image illisible » d'une erreur Vision proprement dite.
    guard UIImage(contentsOfFile: imagePath)?.cgImage != nil else {
      result(FlutterError(
        code: "invalid_image",
        message: "Image illisible : \(imagePath)",
        details: nil
      ))
      return
    }

    // Vision peut prendre ~1 s sur une photo 12 Mpx : hors du thread
    // principal. FlutterResult est appelable depuis n'importe quel thread.
    DispatchQueue.global(qos: .userInitiated).async {
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          result(FlutterError(
            code: "vision_error",
            message: error.localizedDescription,
            details: nil
          ))
          return
        }
        let lines = (request.results as? [VNRecognizedTextObservation])?
          .compactMap { $0.topCandidates(1).first?.string } ?? []
        result(lines.joined(separator: "\n"))
      }
      request.recognitionLevel = .accurate
      // fr-CH / de-CH sont acceptés (Vision retombe sur fr-FR / de-DE).
      // La correction linguistique aide à récupérer les libellés sur photo
      // bruitée et ne modifie pas les montants (vérifié au batch 13 sur
      // une image type certificat de salaire / relevé LPP : sorties
      // identiques avec et sans, apostrophes suisses comprises).
      request.recognitionLanguages = ["fr-CH", "de-CH", "en"]
      request.usesLanguageCorrection = true

      // Le handler basé URL applique l'orientation EXIF automatiquement.
      let handler = VNImageRequestHandler(
        url: URL(fileURLWithPath: imagePath),
        options: [:]
      )
      do {
        try handler.perform([request])
      } catch {
        result(FlutterError(
          code: "vision_error",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }
}
