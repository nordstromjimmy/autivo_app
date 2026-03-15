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

/// Service to handle the complete verification flow
class VerificationService {
  final PhotoService _photoService = PhotoService();
  final OCRService _ocrService = OCRService();

  /// Verify a vehicle with a photo of registration certificate
  Future<VerificationResult> verifyVehicle(
    Vehicle vehicle,
    File photoFile,
  ) async {
    try {
      // Step 1: Run OCR and validate document
      final DocumentVerification validation = await _ocrService
          .validateDocument(photoFile, vehicle.registrationNumber);

      // Step 2: Check if valid
      if (!validation.isValid) {
        return VerificationResult(
          success: false,
          message: validation.statusMessage,
          confidenceScore: validation.confidenceScore,
          documentVerification: validation,
        );
      }

      // Step 3: Save photo locally
      final String? savedPath = await _photoService.saveVerificationPhoto(
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

      // Success!
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

  /// Get verification photo for a vehicle
  Future<File?> getVerificationPhoto(String vehicleId) async {
    return await _photoService.getVerificationPhoto(vehicleId);
  }

  /// Delete verification and photo for a vehicle
  Future<bool> deleteVerification(String vehicleId) async {
    return await _photoService.deleteVerificationPhoto(vehicleId);
  }

  /// Check if vehicle has verification photo
  Future<bool> hasVerificationPhoto(String vehicleId) async {
    return await _photoService.hasVerificationPhoto(vehicleId);
  }

  /// Dispose resources
  void dispose() {
    _ocrService.dispose();
  }
}
