import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling photo capture, selection, and local storage
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Take a photo using the camera
  Future<File?> takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  /// Pick a photo from the gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      print('Error picking from gallery: $e');
      return null;
    }
  }

  /// Save photo locally for a specific vehicle
  /// Returns the local file path
  Future<String?> saveVerificationPhoto(File photo, String vehicleId) async {
    try {
      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // Create verification_photos subdirectory if it doesn't exist
      final Directory verificationDir = Directory(
        path.join(appDocDir.path, 'verification_photos'),
      );

      if (!await verificationDir.exists()) {
        await verificationDir.create(recursive: true);
      }

      // Create filename: {vehicleId}_registration.jpg
      final String fileName = '${vehicleId}_registration.jpg';
      final String filePath = path.join(verificationDir.path, fileName);

      // Copy photo to permanent location
      final File savedFile = await photo.copy(filePath);

      return savedFile.path;
    } catch (e) {
      print('Error saving photo: $e');
      return null;
    }
  }

  /// Get verification photo for a vehicle
  Future<File?> getVerificationPhoto(String vehicleId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = path.join(
        appDocDir.path,
        'verification_photos',
        '${vehicleId}_registration.jpg',
      );

      final File file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting photo: $e');
      return null;
    }
  }

  /// Delete verification photo for a vehicle
  Future<bool> deleteVerificationPhoto(String vehicleId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = path.join(
        appDocDir.path,
        'verification_photos',
        '${vehicleId}_registration.jpg',
      );

      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Check if verification photo exists for a vehicle
  Future<bool> hasVerificationPhoto(String vehicleId) async {
    final photo = await getVerificationPhoto(vehicleId);
    return photo != null;
  }
}
