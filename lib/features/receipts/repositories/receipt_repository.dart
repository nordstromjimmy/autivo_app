import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt.dart';
import '../../../core/services/storage/image_compression_service.dart';
import '../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptRepository {
  static const String boxName = 'receipts';
  static const String bucketName = 'receipts';

  final ImageCompressionService _compressionService = ImageCompressionService();
  final _supabase = Supabase.instance.client;

  // Get Hive box
  Box<Receipt> get _box => Hive.box<Receipt>(boxName);

  // ==================== LOCAL OPERATIONS ====================

  /// Get all receipts for a vehicle
  List<Receipt> getByVehicleId(String vehicleId) {
    return _box.values.where((r) => r.vehicleId == vehicleId).toList();
  }

  /// Get receipts for a specific maintenance record
  List<Receipt> getByMaintenanceId(String maintenanceId) {
    return _box.values
        .where((r) => r.maintenanceRecordId == maintenanceId)
        .toList();
  }

  /// Get receipt by ID
  Receipt? getById(String id) {
    return _box.get(id);
  }

  /// Get all receipts
  List<Receipt> getAll() {
    return _box.values.toList();
  }

  /// Add new receipt (with image compression and upload)
  Future<Receipt> add({
    required File imageFile,
    required String vehicleId,
    String? maintenanceRecordId,
    String? description,
    DateTime? date,
    double? amount,
  }) async {
    try {
      // Step 1: Compress image
      final compressed = await _compressionService.compressReceiptImage(
        imageFile,
      );

      // Step 2: Create receipt model
      final userId = SupabaseConfig.currentUserId ?? '';
      final receiptId = DateTime.now().millisecondsSinceEpoch.toString();

      // Generate storage path
      final storagePath = '$userId/$vehicleId/$receiptId.jpg';

      final receipt = Receipt(
        id: receiptId,
        userId: userId,
        vehicleId: vehicleId,
        maintenanceRecordId: maintenanceRecordId,
        storagePath: storagePath,
        fileName: compressed.file.path.split('/').last,
        fileSize: compressed.compressedSize,
        mimeType: compressed.mimeType,
        width: compressed.width,
        height: compressed.height,
        description: description,
        date: date,
        amount: amount,
        needsSync: true,
        localFilePath: compressed.file.path, // Store local path temporarily
      );

      // Step 3: Save to Hive first (local-first)
      await _box.put(receipt.id, receipt);

      // Step 4: Try to upload if signed in
      if (SupabaseConfig.isSignedIn) {
        await _trySyncReceipt(receipt);
      }

      return receipt;
    } catch (e) {
      print('❌ Error adding receipt: $e');
      rethrow;
    }
  }

  /// Update receipt metadata
  Future<void> update(Receipt receipt) async {
    try {
      // Mark for sync
      receipt.markForSync();

      // Update in Hive
      await _box.put(receipt.id, receipt);

      // Try to sync if signed in
      if (SupabaseConfig.isSignedIn) {
        await _updateReceiptMetadata(receipt);
      }
    } catch (e) {
      print('❌ Error updating receipt: $e');
      rethrow;
    }
  }

  /// Delete receipt (local and cloud)
  Future<void> delete(String receiptId) async {
    try {
      final receipt = getById(receiptId);
      if (receipt == null) return;

      // Delete local file if exists
      if (receipt.localFilePath != null) {
        final localFile = File(receipt.localFilePath!);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }

      // Delete from cloud if synced
      if (receipt.supabaseId != null && SupabaseConfig.isSignedIn) {
        await _deleteFromStorage(receipt.storagePath);
        await _deleteMetadata(receipt.supabaseId!);
      }

      // Delete from Hive
      await _box.delete(receiptId);
    } catch (e) {
      print('❌ Error deleting receipt: $e');
      rethrow;
    }
  }

  /// Delete all receipts for a vehicle
  Future<void> deleteByVehicleId(String vehicleId) async {
    try {
      final receipts = getByVehicleId(vehicleId);

      for (final receipt in receipts) {
        await delete(receipt.id);
      }
    } catch (e) {
      print('❌ Error deleting vehicle receipts: $e');
      rethrow;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync a single receipt to cloud
  Future<bool> _trySyncReceipt(Receipt receipt) async {
    try {
      // Upload image file
      if (receipt.localFilePath != null) {
        final imageFile = File(receipt.localFilePath!);

        if (await imageFile.exists()) {
          // Upload to storage
          await _uploadToStorage(
            imageFile: imageFile,
            storagePath: receipt.storagePath,
          );

          // Upload metadata
          final cloudId = await _uploadMetadata(receipt);

          // Mark as synced
          receipt.markSynced(cloudId);
          await _box.put(receipt.id, receipt);

          return true;
        } else {
          print('  ❌ File does not exist: ${receipt.localFilePath}');
          return false;
        }
      } else {
        print('  ❌ No local file path set');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error syncing receipt ${receipt.id}: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Sync all pending receipts to cloud
  Future<int> syncPending() async {
    if (!SupabaseConfig.isSignedIn) {
      print('⚠️ Cannot sync receipts: User not signed in');
      return 0;
    }

    final pendingReceipts = _box.values.where((r) => r.needsSync).toList();

    int syncedCount = 0;

    for (final receipt in pendingReceipts) {
      if (await _trySyncReceipt(receipt)) {
        syncedCount++;
      } else {
        print('❌ Failed to sync receipt ${receipt.id}');
      }
    }

    return syncedCount;
  }

  /// Pull receipts from cloud for a vehicle
  Future<void> pullFromCloud(String vehicleId) async {
    if (!SupabaseConfig.isSignedIn) return;

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;

      // Download metadata
      final cloudReceipts = await _downloadMetadata(
        userId: userId,
        vehicleId: vehicleId,
      );

      // Get local receipts for this vehicle
      final localReceipts = getByVehicleId(vehicleId);
      final localIds = localReceipts.map((r) => r.id).toSet();
      final cloudIds = cloudReceipts.map((r) => r.id).toSet();

      // Remove local receipts not in cloud (unless pending sync)
      for (final localId in localIds) {
        if (!cloudIds.contains(localId)) {
          final localReceipt = _box.get(localId);

          // Don't delete if pending upload
          if (localReceipt != null && localReceipt.needsSync) {
            continue;
          }

          // Delete local receipt not in cloud
          await _box.delete(localId);
        }
      }

      // Add or merge receipts from cloud
      for (final cloudReceipt in cloudReceipts) {
        final localReceipt = _box.get(cloudReceipt.id);

        if (localReceipt == null) {
          // New from cloud - add it
          await _box.put(cloudReceipt.id, cloudReceipt);
        } else if (!localReceipt.needsSync) {
          // Update from cloud if not pending sync
          await _box.put(cloudReceipt.id, cloudReceipt);
        }
        // If needsSync, keep local version
      }
    } catch (e) {
      print('❌ Error pulling receipts from cloud: $e');
      rethrow;
    }
  }

  /// Get local file for receipt (download if needed)
  Future<File?> getLocalFile(Receipt receipt) async {
    try {
      // Check if local file exists
      if (receipt.localFilePath != null) {
        final localFile = File(receipt.localFilePath!);
        if (await localFile.exists()) {
          return localFile;
        }
      }

      // Download from cloud if needed
      if (receipt.supabaseId != null && SupabaseConfig.isSignedIn) {
        final tempDir = await getTemporaryDirectory();
        final localPath = '${tempDir.path}/${receipt.fileName}';

        final downloadedFile = await _downloadFromStorage(
          storagePath: receipt.storagePath,
          localPath: localPath,
        );

        // Update local path
        final updatedReceipt = receipt.copyWith(localFilePath: localPath);
        await _box.put(receipt.id, updatedReceipt);

        return downloadedFile;
      }

      return null;
    } catch (e) {
      print('❌ Error getting local file: $e');
      return null;
    }
  }

  /// Get count of receipts pending sync
  int getPendingSyncCount() {
    return _box.values.where((r) => r.needsSync).length;
  }

  /// Assign userId to all local receipts (for migration)
  /// Assign userId to all local receipts (for migration)
  Future<void> assignUserToAllReceipts(String userId) async {
    final receipts = _box.values.toList();

    // Filter only receipts that need migration (null or empty userId)
    final needsMigration = receipts.where((r) => r.userId.isEmpty).toList();

    if (needsMigration.isEmpty) {
      return;
    }

    for (final receipt in needsMigration) {
      // Fix storagePath if it doesn't start with userId
      String fixedStoragePath = receipt.storagePath;

      // If path starts with "/" or doesn't have userId, fix it
      if (fixedStoragePath.startsWith('/')) {
        // Remove leading slash and prepend userId
        fixedStoragePath = '$userId${fixedStoragePath}';
      } else if (!fixedStoragePath.startsWith(userId)) {
        // Path exists but doesn't start with userId, prepend it
        fixedStoragePath = '$userId/$fixedStoragePath';
      }

      final updated = receipt.copyWith(
        userId: userId,
        storagePath: fixedStoragePath,
        needsSync: true,
      );

      await _box.put(receipt.id, updated);
    }
  }

  // ==================== SUPABASE STORAGE OPERATIONS ====================

  /// Upload image to Supabase Storage
  Future<void> _uploadToStorage({
    required File imageFile,
    required String storagePath,
  }) async {
    await _supabase.storage
        .from(bucketName)
        .upload(
          storagePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
  }

  /// Download image from Supabase Storage
  Future<File> _downloadFromStorage({
    required String storagePath,
    required String localPath,
  }) async {
    final bytes = await _supabase.storage
        .from(bucketName)
        .download(storagePath);
    final file = File(localPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Delete image from Supabase Storage
  Future<void> _deleteFromStorage(String storagePath) async {
    await _supabase.storage.from(bucketName).remove([storagePath]);
  }

  // ==================== SUPABASE DATABASE OPERATIONS ====================

  /// Upload receipt metadata to database
  Future<String> _uploadMetadata(Receipt receipt) async {
    final response = await _supabase
        .from('receipts')
        .insert(receipt.toJson())
        .select()
        .single();

    return response['id'] as String;
  }

  /// Update receipt metadata in database
  Future<void> _updateReceiptMetadata(Receipt receipt) async {
    await _supabase
        .from('receipts')
        .update(receipt.toJson())
        .eq('id', receipt.supabaseId ?? receipt.id);

    receipt.markSynced(receipt.supabaseId ?? receipt.id);
    await _box.put(receipt.id, receipt);
  }

  /// Download receipt metadata from database
  Future<List<Receipt>> _downloadMetadata({
    required String userId,
    String? vehicleId,
  }) async {
    var query = _supabase.from('receipts').select().eq('user_id', userId);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((data) => Receipt.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  /// Delete receipt metadata from database
  Future<void> _deleteMetadata(String receiptId) async {
    await _supabase.from('receipts').delete().eq('id', receiptId);
  }
}
