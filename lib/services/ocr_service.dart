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

  /// Check if document is valid (all 3 checks must pass)
  bool get isValid {
    return registrationNumberFound &&
        hasRegistreringsbevis &&
        hasTransportstyrelsen;
  }

  /// Get a confidence score (0-100)
  int get confidenceScore {
    int score = 0;
    if (registrationNumberFound) score += 40; // Most important
    if (hasRegistreringsbevis) score += 30;
    if (hasTransportstyrelsen) score += 30;
    return score;
  }

  /// Get a user-friendly status message
  String get statusMessage {
    if (isValid) {
      return 'Verifierad! Dokumentet är giltigt.';
    }

    final List<String> missing = [];
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
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Combine all text blocks into one string
      final StringBuffer buffer = StringBuffer();
      for (TextBlock block in recognizedText.blocks) {
        buffer.writeln(block.text);
      }

      return buffer.toString();
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  /// Validate a document against a vehicle's registration number
  Future<DocumentVerification> validateDocument(
    File imageFile,
    String expectedRegistrationNumber,
  ) async {
    // Extract all text from image
    final String extractedText = await extractText(imageFile);

    if (extractedText.isEmpty) {
      return DocumentVerification(
        registrationNumberFound: false,
        hasRegistreringsbevis: false,
        hasTransportstyrelsen: false,
        extractedText: '',
      );
    }

    // Normalize text for searching
    final String normalizedText = extractedText.toUpperCase();
    final String normalizedRegNumber = expectedRegistrationNumber
        .toUpperCase()
        .replaceAll(' ', '');

    // Check 1: Registration number found
    final bool regNumberFound = _findRegistrationNumber(
      normalizedText,
      normalizedRegNumber,
    );

    // Check 2: "Registreringsbevis" keyword found
    final bool hasRegistreringsbevis = normalizedText.contains(
      'REGISTRERINGSBEVIS',
    );

    // Check 3: "Transportstyrelsen" keyword found
    final bool hasTransportstyrelsen = normalizedText.contains(
      'TRANSPORTSTYRELSEN',
    );

    return DocumentVerification(
      registrationNumberFound: regNumberFound,
      hasRegistreringsbevis: hasRegistreringsbevis,
      hasTransportstyrelsen: hasTransportstyrelsen,
      extractedText: extractedText,
    );
  }

  /// Find registration number in text
  /// Swedish format: ABC123 or ABC12D
  bool _findRegistrationNumber(String text, String expectedRegNumber) {
    // Remove all spaces from text
    final String cleanText = text.replaceAll(' ', '');
    final String cleanExpected = expectedRegNumber.replaceAll(' ', '');

    // Direct match
    if (cleanText.contains(cleanExpected)) {
      return true;
    }

    // Try with spaces/dashes that OCR might have added
    // ABC 123, ABC-123, etc.
    final String regPattern = expectedRegNumber.replaceAll('', r'[\s\-]?');
    final RegExp regex = RegExp(regPattern, caseSensitive: false);

    if (regex.hasMatch(text)) {
      return true;
    }

    // Swedish registration number pattern: 3 letters + 2-3 digits + optional letter
    // ABC123, ABC12D
    final RegExp sweRegPattern = RegExp(r'[A-Z]{3}\s?\d{2,3}\s?[A-Z]?');
    final Iterable<Match> matches = sweRegPattern.allMatches(cleanText);

    for (final match in matches) {
      final String found = match.group(0)?.replaceAll(' ', '') ?? '';
      if (found == cleanExpected) {
        return true;
      }
    }

    return false;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
