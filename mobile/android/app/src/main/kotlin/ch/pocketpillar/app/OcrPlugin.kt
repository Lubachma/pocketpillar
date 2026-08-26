package ch.pocketpillar.app

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Plugin OCR maison — reconnaissance de texte **on-device** via ML Kit
 * (dépendance Gradle `com.google.mlkit:text-recognition`, donc Android
 * uniquement : rien n'est linké côté iOS, où Apple Vision prend le relais —
 * voir `ios/Runner/OcrPlugin.swift`).
 *
 * Remplace le package pub `google_mlkit_text_recognition`, dont les binaires
 * iOS n'ont pas de slice arm64 simulateur (iOS 26 n'exécutant plus de
 * x86_64, le simulateur iOS était inutilisable).
 *
 * Contrat du channel `ch.pocketpillar.app/ocr` (identique à iOS) :
 * - méthode `recognizeText`, argument `imagePath` (String) ;
 * - retour : le texte brut, lignes jointes par `\n` (parsing côté Dart) ;
 * - erreurs : `bad_args`, `file_not_found`, `invalid_image`, `mlkit_error`.
 */
class OcrPlugin private constructor(context: android.content.Context) :
    MethodChannel.MethodCallHandler {

    private val appContext = context.applicationContext

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "recognizeText") {
            result.notImplemented()
            return
        }
        val imagePath = call.argument<String>("imagePath")
        if (imagePath == null) {
            result.error("bad_args", "Argument « imagePath » (String) attendu.", null)
            return
        }
        if (!File(imagePath).exists()) {
            result.error("file_not_found", "Fichier introuvable : $imagePath", null)
            return
        }
        val image = try {
            InputImage.fromFilePath(appContext, Uri.fromFile(File(imagePath)))
        } catch (e: Exception) {
            result.error("invalid_image", "Image illisible : $imagePath (${e.localizedMessage})", null)
            return
        }
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer.process(image)
            .addOnSuccessListener { text ->
                recognizer.close()
                result.success(text.text)
            }
            .addOnFailureListener { e ->
                recognizer.close()
                result.error("mlkit_error", e.localizedMessage, null)
            }
    }

    companion object {
        private const val CHANNEL_NAME = "ch.pocketpillar.app/ocr"

        fun register(messenger: BinaryMessenger, context: android.content.Context) {
            MethodChannel(messenger, CHANNEL_NAME)
                .setMethodCallHandler(OcrPlugin(context))
        }
    }
}
