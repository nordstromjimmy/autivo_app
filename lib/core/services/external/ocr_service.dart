import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of document validation
class DocumentVerification {
  final bool registrationNumberFound;
  final bool hasRegistreringsbevis;
  final bool hasTransportstyrelsen;
  final String extractedText;

  DocumentVerification({
    required this.registrationNumberFound,
    required this.hasRegistreringsbevis,
    required this.hasTransportstyrelsen,
    required this.extractedText,
  });

  /// All 3 checks must pass for a valid document
  bool get isValid =>
      registrationNumberFound && hasRegistreringsbevis && hasTransportstyrelsen;

  /// Confidence score (0–100)
  int get confidenceScore {
    int score = 0;
    if (registrationNumberFound) score += 40;
    if (hasRegistreringsbevis) score += 30;
    if (hasTransportstyrelsen) score += 30;
    return score;
  }

  /// User-friendly status message
  String get statusMessage {
    if (isValid) return 'Verifierad! Dokumentet är giltigt.';

    final missing = <String>[];
    if (!registrationNumberFound) missing.add('registreringsnummer');
    if (!hasRegistreringsbevis) missing.add('"Registreringsbevis"');
    if (!hasTransportstyrelsen) missing.add('"Transportstyrelsen"');

    return 'Hittade inte: ${missing.join(', ')}';
  }
}

/// Service for OCR text extraction and document validation
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image using OCR
  Future<String> _extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        buffer.writeln(block.text);
      }
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  /// Validate a registration document against a vehicle's registration number
  Future<DocumentVerification> validateDocument(
    File imageFile,
    String expectedRegistrationNumber,
  ) async {
    final extractedText = await _extractText(imageFile);

    if (extractedText.isEmpty) {
      return DocumentVerification(
        registrationNumberFound: false,
        hasRegistreringsbevis: false,
        hasTransportstyrelsen: false,
        extractedText: '',
      );
    }

    final normalizedText = extractedText.toUpperCase();
    final normalizedRegNumber = expectedRegistrationNumber
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\-]'), '');

    return DocumentVerification(
      registrationNumberFound: _findRegistrationNumber(
        normalizedText,
        normalizedRegNumber,
      ),
      hasRegistreringsbevis: normalizedText.contains('REGISTRERINGSBEVIS'),
      hasTransportstyrelsen: normalizedText.contains('TRANSPORTSTYRELSEN'),
      extractedText: extractedText,
    );
  }

  /// Find registration number in OCR text.
  /// Strips spaces and dashes from both sides before comparing,
  /// since OCR may insert or omit whitespace.
  bool _findRegistrationNumber(String text, String expectedRegNumber) {
    final cleanText = text.replaceAll(RegExp(r'[\s\-]'), '');
    return cleanText.contains(expectedRegNumber);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
