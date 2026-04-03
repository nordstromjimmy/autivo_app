import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt.dart';
import '../../../core/services/storage/image_compression_service.dart';
import '../../../core/services/storage/storage_limit_service.dart';
import '../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptRepository {
  static const String boxName = 'receipts';
  static const String bucketName = 'receipts';

  final ImageCompressionService _compressionService = ImageCompressionService();
  final StorageLimitService _storageLimitService = StorageLimitService();
  final _supabase = Supabase.instance.client;

  Box<Receipt> get _box => Hive.box<Receipt>(boxName);

  // ==================== LOCAL OPERATIONS ====================

  List<Receipt> getByVehicleId(String vehicleId) {
    return _box.values.where((r) => r.vehicleId == vehicleId).toList();
  }

  List<Receipt> getByMaintenanceId(String maintenanceId) {
    return _box.values
        .where((r) => r.maintenanceRecordId == maintenanceId)
        .toList();
  }

  Receipt? getById(String id) => _box.get(id);

  List<Receipt> getAll() => _box.values.toList();

  /// Add new receipt (with image compression, storage limit check, and upload).
  /// [isPremium] must be passed by the caller (e.g. from your premium provider).
  Future<Receipt> add({
    required File imageFile,
    required String vehicleId,
    required bool isPremium,
    String? maintenanceRecordId,
    String? description,
    DateTime? date,
    double? amount,
  }) async {
    // Step 1: Compress image
    final compressed = await _compressionService.compressReceiptImage(
      imageFile,
    );

    // Step 2: Check storage limit before doing anything else.
    // Only enforced for signed-in users since anonymous users are local-only.
    if (SupabaseConfig.isSignedIn) {
      final fileSizeMb = compressed.compressedSize / 1048576.0;
      final check = await _storageLimitService.checkCanUpload(
        isPremium: isPremium,
        fileSizeMb: fileSizeMb,
      );
      if (!check.allowed) {
        throw StorageLimitException(check.reason!);
      }
    }

    // Step 3: Build receipt model
    final userId = SupabaseConfig.currentUserId ?? '';
    final receiptId = DateTime.now().millisecondsSinceEpoch.toString();
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
      localFilePath: compressed.file.path,
    );

    // Step 4: Save locally first (local-first approach)
    await _box.put(receipt.id, receipt);

    // Step 5: Upload if signed in
    if (SupabaseConfig.isSignedIn) {
      await _trySyncReceipt(receipt);
    }

    return receipt;
  }

  /// Update receipt metadata
  Future<void> update(Receipt receipt) async {
    final updatedReceipt = receipt.copyWith(
      needsSync: true,
      updatedAt: DateTime.now(),
    );

    await _box.put(updatedReceipt.id, updatedReceipt);

    if (SupabaseConfig.isSignedIn) {
      await _updateReceiptMetadata(updatedReceipt);
    }
  }

  /// Delete receipt (local and cloud).
  /// Local cleanup always runs — a cloud failure will not leave a
  /// dangling local record that the user can no longer remove.
  Future<void> delete(String receiptId) async {
    final receipt = getById(receiptId);
    if (receipt == null) return;

    // 1. Delete local file
    if (receipt.localFilePath != null) {
      final localFile = File(receipt.localFilePath!);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }

    // 2. Remove from Hive first — always succeeds locally regardless
    //    of what happens with the cloud deletion below.
    await _box.delete(receiptId);

    // 3. Best-effort cloud deletion — use storagePath (always set) for
    //    Storage, and supabaseId ?? receipt.id for the metadata row.
    //    This handles the case where supabaseId was never populated locally
    //    (e.g. receipt was created on another device).
    if (SupabaseConfig.isSignedIn && receipt.storagePath.isNotEmpty) {
      try {
        await _deleteFromStorage(receipt.storagePath);
        await _deleteMetadata(receipt.supabaseId ?? receipt.id);
      } catch (_) {
        // Cloud delete failed (e.g. connection dropped). The file may
        // remain in Supabase Storage but is already gone locally.
      }
    }
  }

  /// Delete all receipts for a vehicle
  Future<void> deleteByVehicleId(String vehicleId) async {
    final receipts = getByVehicleId(vehicleId);
    for (final receipt in receipts) {
      await delete(receipt.id);
    }
  }

  // ==================== SYNC OPERATIONS ====================

  Future<bool> _trySyncReceipt(Receipt receipt) async {
    try {
      if (receipt.localFilePath == null) return false;

      final imageFile = File(receipt.localFilePath!);
      if (!await imageFile.exists()) return false;

      final fileSize = await imageFile.length();

      await _uploadToStorage(
        imageFile: imageFile,
        storagePath: receipt.storagePath,
      );

      final cloudId = await _uploadMetadata(receipt, fileSize);
      receipt.markSynced(cloudId!);
      await _box.put(receipt.id, receipt);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> syncPending() async {
    if (!SupabaseConfig.isSignedIn) return 0;

    final pendingReceipts = _box.values.where((r) => r.needsSync).toList();
    int syncedCount = 0;

    for (final receipt in pendingReceipts) {
      if (await _trySyncReceipt(receipt)) syncedCount++;
    }

    return syncedCount;
  }

  Future<void> pullFromCloud(String vehicleId) async {
    if (!SupabaseConfig.isSignedIn) return;

    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;

    final cloudReceipts = await _downloadMetadata(
      userId: userId,
      vehicleId: vehicleId,
    );

    final localReceipts = getByVehicleId(vehicleId);
    final localIds = localReceipts.map((r) => r.id).toSet();
    final cloudIds = cloudReceipts.map((r) => r.id).toSet();

    for (final localId in localIds) {
      if (!cloudIds.contains(localId)) {
        final localReceipt = _box.get(localId);
        if (localReceipt != null && localReceipt.needsSync) continue;
        await _box.delete(localId);
      }
    }

    for (final cloudReceipt in cloudReceipts) {
      final localReceipt = _box.get(cloudReceipt.id);
      if (localReceipt == null || !localReceipt.needsSync) {
        await _box.put(cloudReceipt.id, cloudReceipt);
      }
    }
  }

  Future<File?> getLocalFile(Receipt receipt) async {
    try {
      if (receipt.localFilePath != null) {
        final localFile = File(receipt.localFilePath!);
        if (await localFile.exists()) return localFile;
      }

      if (receipt.supabaseId != null && SupabaseConfig.isSignedIn) {
        final tempDir = await getTemporaryDirectory();
        final fileName = receipt.storagePath.split('/').last;
        final localPath = '${tempDir.path}/$fileName';

        final downloadedFile = await _downloadFromStorage(
          storagePath: receipt.storagePath,
          localPath: localPath,
        );

        final updatedReceipt = receipt.copyWith(localFilePath: localPath);
        await _box.put(receipt.id, updatedReceipt);

        return downloadedFile;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  int getPendingSyncCount() {
    return _box.values.where((r) => r.needsSync).length;
  }

  Future<void> assignUserToAllReceipts(String userId) async {
    final needsMigration = _box.values.where((r) => r.userId.isEmpty).toList();
    if (needsMigration.isEmpty) return;

    for (final receipt in needsMigration) {
      String fixedStoragePath = receipt.storagePath;

      if (fixedStoragePath.startsWith('/')) {
        fixedStoragePath = '$userId$fixedStoragePath';
      } else if (!fixedStoragePath.startsWith(userId)) {
        fixedStoragePath = '$userId/$fixedStoragePath';
      }

      await _box.put(
        receipt.id,
        receipt.copyWith(
          userId: userId,
          storagePath: fixedStoragePath,
          needsSync: true,
        ),
      );
    }
  }

  // ==================== SUPABASE STORAGE ====================

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

  Future<void> _deleteFromStorage(String storagePath) async {
    await _supabase.storage.from(bucketName).remove([storagePath]);
  }

  // ==================== SUPABASE DATABASE ====================

  Future<String?> _uploadMetadata(Receipt receipt, int fileSize) async {
    final fileName = receipt.storagePath.split('/').last;

    final response = await _supabase
        .from('receipts')
        .upsert({
          'id': receipt.id,
          'user_id': receipt.userId,
          'vehicle_id': receipt.vehicleId,
          'maintenance_record_id': receipt.maintenanceRecordId,
          'description': receipt.description,
          'date': receipt.date?.toIso8601String(),
          'amount': receipt.amount,
          'storage_path': receipt.storagePath,
          'file_name': fileName,
          'file_size': fileSize,
          'mime_type': 'image/jpeg',
          'created_at': receipt.createdAt.toIso8601String(),
          'updated_at': receipt.updatedAt.toIso8601String(),
        })
        .select()
        .single();

    return response['id'] as String;
  }

  Future<void> _updateReceiptMetadata(Receipt receipt) async {
    await _supabase
        .from('receipts')
        .update({
          'description': receipt.description,
          'date': receipt.date?.toIso8601String(),
          'amount': receipt.amount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', receipt.supabaseId ?? receipt.id);

    await _box.put(
      receipt.id,
      receipt.copyWith(needsSync: false, lastSyncedAt: DateTime.now()),
    );
  }

  Future<List<Receipt>> _downloadMetadata({
    required String userId,
    String? vehicleId,
  }) async {
    var query = _supabase.from('receipts').select().eq('user_id', userId);
    if (vehicleId != null) query = query.eq('vehicle_id', vehicleId);

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((data) => Receipt.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  Future<void> _deleteMetadata(String receiptId) async {
    await _supabase.from('receipts').delete().eq('id', receiptId);
  }
}
