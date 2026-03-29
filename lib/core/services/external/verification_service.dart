import 'dart:io';
import '../../../features/vehicles/models/vehicle.dart';
import '../media/photo_service.dart';
import 'ocr_service.dart';

/// Result of the verification process
class VerificationResult {
  final bool success;
  final String message;
  final int? confidenceScore;
  final String? photoPath;
  final DocumentVerification? documentVerification;

  VerificationResult({
    required this.success,
    required this.message,
    this.confidenceScore,
    this.photoPath,
    this.documentVerification,
  });
}

/// Service to handle the complete verification flow:
/// OCR validation → photo storage
class VerificationService {
  final PhotoService _photoService = PhotoService();
  final OCRService _ocrService = OCRService();

  /// Verify a vehicle with a photo of its registration certificate.
  /// Returns success only if all 3 OCR checks pass and the photo is saved.
  Future<VerificationResult> verifyVehicle(
    Vehicle vehicle,
    File photoFile,
  ) async {
    try {
      final validation = await _ocrService.validateDocument(
        photoFile,
        vehicle.registrationNumber,
      );

      if (!validation.isValid) {
        return VerificationResult(
          success: false,
          message: validation.statusMessage,
          confidenceScore: validation.confidenceScore,
          documentVerification: validation,
        );
      }

      final savedPath = await _photoService.saveVerificationPhoto(
        photoFile,
        vehicle.id,
      );

      if (savedPath == null) {
        return VerificationResult(
          success: false,
          message: 'Kunde inte spara foto',
          confidenceScore: validation.confidenceScore,
          documentVerification: validation,
        );
      }

      return VerificationResult(
        success: true,
        message: 'Fordon verifierat!',
        confidenceScore: validation.confidenceScore,
        photoPath: savedPath,
        documentVerification: validation,
      );
    } catch (e) {
      return VerificationResult(
        success: false,
        message: 'Fel vid verifiering: $e',
      );
    }
  }

  /// Delete verification photo for a vehicle
  Future<bool> deleteVerification(String vehicleId) async {
    return _photoService.deleteVerificationPhoto(vehicleId);
  }

  void dispose() {
    _ocrService.dispose();
  }
}
