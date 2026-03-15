import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';
import 'maintenance_provider.dart';

// Provider for the receipt repository
final receiptRepositoryProvider = Provider((ref) => ReceiptRepository());

// Receipt notifier (manages all receipts)
final receiptNotifierProvider = NotifierProvider<ReceiptNotifier, void>(
  ReceiptNotifier.new,
);

class ReceiptNotifier extends Notifier<void> {
  late ReceiptRepository _repository;

  @override
  void build() {
    _repository = ref.read(receiptRepositoryProvider);
  }

  /// Add a new receipt
  Future<Receipt> addReceipt({
    required File imageFile,
    required String vehicleId,
    String? maintenanceRecordId,
    String? description,
    DateTime? date,
    double? amount,
  }) async {
    final receipt = await _repository.add(
      imageFile: imageFile,
      vehicleId: vehicleId,
      maintenanceRecordId: maintenanceRecordId,
      description: description,
      date: date,
      amount: amount,
    );

    // Invalidate relevant providers
    ref.invalidate(receiptsForVehicleProvider(vehicleId));
    if (maintenanceRecordId != null) {
      ref.invalidate(receiptsForMaintenanceProvider(maintenanceRecordId));
    }
    ref.invalidate(receiptByIdProvider(receipt.id));
    ref.invalidate(pendingSyncCountProvider);

    return receipt;
  }

  /// Update receipt metadata
  Future<void> updateReceipt(Receipt receipt) async {
    await _repository.update(receipt);

    // Invalidate relevant providers
    ref.invalidate(receiptsForVehicleProvider(receipt.vehicleId));
    if (receipt.maintenanceRecordId != null) {
      ref.invalidate(
        receiptsForMaintenanceProvider(receipt.maintenanceRecordId!),
      );
    }
    ref.invalidate(receiptByIdProvider(receipt.id));
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Delete receipt
  Future<void> deleteReceipt(String receiptId) async {
    final receipt = _repository.getById(receiptId);
    await _repository.delete(receiptId);

    // Invalidate relevant providers
    if (receipt != null) {
      ref.invalidate(receiptsForVehicleProvider(receipt.vehicleId));
      if (receipt.maintenanceRecordId != null) {
        ref.invalidate(
          receiptsForMaintenanceProvider(receipt.maintenanceRecordId!),
        );
      }
    }
    ref.invalidate(receiptByIdProvider(receiptId));
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Delete all receipts for a vehicle
  Future<void> deleteVehicleReceipts(String vehicleId) async {
    await _repository.deleteByVehicleId(vehicleId);
    ref.invalidate(receiptsForVehicleProvider(vehicleId));
    ref.invalidate(receiptByIdProvider);
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Sync pending receipts to cloud
  Future<int> syncPending() async {
    final synced = await _repository.syncPending();

    // Invalidate providers
    ref.invalidate(receiptsForVehicleProvider);
    ref.invalidate(receiptByIdProvider);
    ref.invalidate(pendingSyncCountProvider);

    return synced;
  }

  /// Pull receipts from cloud for a vehicle
  Future<void> pullFromCloud(String vehicleId) async {
    await _repository.pullFromCloud(vehicleId);
    ref.invalidate(receiptsForVehicleProvider(vehicleId));
    ref.invalidate(receiptByIdProvider);
  }

  /// Get local file for receipt
  Future<File?> getLocalFile(Receipt receipt) async {
    return await _repository.getLocalFile(receipt);
  }

  /// Get count of receipts needing sync
  int get pendingSyncCount => _repository.getPendingSyncCount();

  /// Assign user ID to all receipts (for migration)
  Future<void> assignUserToAllReceipts(String userId) async {
    await _repository.assignUserToAllReceipts(userId);
  }
}

// Provider for receipts for a specific vehicle
final receiptsForVehicleProvider = Provider.family<List<Receipt>, String>((
  ref,
  vehicleId,
) {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getByVehicleId(vehicleId);
});

// Provider for receipts for a specific maintenance record
final receiptsForMaintenanceProvider = Provider.family<List<Receipt>, String>((
  ref,
  maintenanceId,
) {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getByMaintenanceId(maintenanceId);
});

// Provider for single receipt by ID
final receiptByIdProvider = Provider.family<Receipt?, String>((ref, receiptId) {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getById(receiptId);
});

// Provider for pending sync count
final receiptPendingSyncCountProvider = Provider<int>((ref) {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getPendingSyncCount();
});
