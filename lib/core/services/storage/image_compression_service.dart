import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for compressing receipt images
/// Optimized for PDF export quality while keeping file sizes small
class ImageCompressionService {
  // Target dimensions for receipts
  static const int maxWidth = 2048;
  static const int maxHeight = 2048;

  // JPEG quality (85-90 is sweet spot for receipts)
  static const int jpegQuality = 88;

  // Maximum file size target (2MB)
  static const int targetMaxSize = 2 * 1024 * 1024;

  /// Compress image file for receipt storage
  /// Returns compressed file and metadata
  Future<CompressedImage> compressReceiptImage(File imageFile) async {
    try {
      // Read original image
      final originalBytes = await imageFile.readAsBytes();
      final originalSize = originalBytes.length;

      // Decode image to get dimensions
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      final originalWidth = originalImage.width;
      final originalHeight = originalImage.height;

      // Calculate target dimensions (maintain aspect ratio)
      final targetDimensions = _calculateTargetDimensions(
        originalWidth,
        originalHeight,
      );

      // Compress image
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: targetDimensions.width,
        minHeight: targetDimensions.height,
        quality: jpegQuality,
        format: CompressFormat.jpeg, // Always convert to JPEG
      );

      // If still too large, compress more aggressively
      Uint8List finalBytes = compressedBytes;
      int currentQuality = jpegQuality;

      while (finalBytes.length > targetMaxSize && currentQuality > 60) {
        currentQuality -= 5;
        finalBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: targetDimensions.width,
          minHeight: targetDimensions.height,
          quality: currentQuality,
          format: CompressFormat.jpeg,
        );
      }

      // Save compressed image to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_receipt.jpg';
      final compressedFile = File(path.join(tempDir.path, fileName));
      await compressedFile.writeAsBytes(finalBytes);

      // Calculate compression ratio
      final compressionRatio =
          ((originalSize - finalBytes.length) / originalSize * 100);

      return CompressedImage(
        file: compressedFile,
        originalSize: originalSize,
        compressedSize: finalBytes.length,
        compressionRatio: compressionRatio,
        width: targetDimensions.width,
        height: targetDimensions.height,
        mimeType: 'image/jpeg',
      );
    } catch (e) {
      print('❌ Error compressing image: $e');
      rethrow;
    }
  }

  /// Calculate target dimensions maintaining aspect ratio
  ImageDimensions _calculateTargetDimensions(int width, int height) {
    // If already small enough, keep original size
    if (width <= maxWidth && height <= maxHeight) {
      return ImageDimensions(width: width, height: height);
    }

    // Calculate aspect ratio
    final aspectRatio = width / height;

    int targetWidth;
    int targetHeight;

    if (width > height) {
      // Landscape or square
      targetWidth = maxWidth;
      targetHeight = (maxWidth / aspectRatio).round();
    } else {
      // Portrait
      targetHeight = maxHeight;
      targetWidth = (maxHeight * aspectRatio).round();
    }

    // Ensure we don't exceed max dimensions
    if (targetWidth > maxWidth) {
      targetWidth = maxWidth;
      targetHeight = (maxWidth / aspectRatio).round();
    }
    if (targetHeight > maxHeight) {
      targetHeight = maxHeight;
      targetWidth = (maxHeight * aspectRatio).round();
    }

    return ImageDimensions(width: targetWidth, height: targetHeight);
  }

  /// Get image dimensions without loading full image
  Future<ImageDimensions> getImageDimensions(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return ImageDimensions(width: image.width, height: image.height);
  }

  /// Validate image file
  Future<bool> isValidImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }
}

/// Compressed image result
class CompressedImage {
  final File file;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final int width;
  final int height;
  final String mimeType;

  CompressedImage({
    required this.file,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.width,
    required this.height,
    required this.mimeType,
  });

  String get displayOriginalSize => _formatBytes(originalSize);
  String get displayCompressedSize => _formatBytes(compressedSize);
  String get displayCompressionRatio =>
      '${compressionRatio.toStringAsFixed(1)}%';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});

  double get aspectRatio => width / height;

  String get displayDimensions => '${width}x$height';
}
