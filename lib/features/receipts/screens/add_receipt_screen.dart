import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../premium/screens/paywall_screen.dart';
import '../../premium/utils/receipt_limit_checker.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';

class AddReceiptScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? maintenanceRecordId;
  final Receipt? existingReceipt; // null = add mode, not null = edit mode

  const AddReceiptScreen({
    super.key,
    required this.vehicleId,
    this.maintenanceRecordId,
    this.existingReceipt,
  });

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  File? _imageFile;
  DateTime? _selectedDate;
  bool _isUploading = false;

  bool get isEditMode => widget.existingReceipt != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if editing
    if (isEditMode) {
      final receipt = widget.existingReceipt!;
      _descriptionController = TextEditingController(
        text: receipt.description ?? '',
      );
      _amountController = TextEditingController(
        text: receipt.amount?.toStringAsFixed(0) ?? '',
      );
      _selectedDate = receipt.date;
    } else {
      _descriptionController = TextEditingController();
      _amountController = TextEditingController();
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ta foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Välj från galleri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveReceipt() async {
    if (!isEditMode && _imageFile == null) {
      CustomSnackBar.showError(context, 'Välj en bild först');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        if (isEditMode) {
          // Update existing receipt
          final updatedReceipt = widget.existingReceipt!.copyWith(
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            date: _selectedDate,
            amount: _amountController.text.isNotEmpty
                ? double.tryParse(_amountController.text)
                : null,
          );

          await ref
              .read(receiptNotifierProvider.notifier)
              .updateReceipt(updatedReceipt);
        } else {
          // Add new receipt
          await ref
              .read(receiptNotifierProvider.notifier)
              .addReceipt(
                imageFile: _imageFile!,
                vehicleId: widget.vehicleId,
                maintenanceRecordId: widget.maintenanceRecordId,
                description: _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
                date: _selectedDate,
                amount: _amountController.text.isNotEmpty
                    ? double.tryParse(_amountController.text)
                    : null,
              );
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          CustomSnackBar.showSuccess(
            context,
            isEditMode ? 'Kvitto uppdaterat' : 'Kvitto tillagt',
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          CustomSnackBar.showError(context, 'Kunde inte spara kvitto: $e');
        }
      }
    }
  }

  void _deleteReceipt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort kvitto?'),
        content: const Text('Kvittot kommer att tas bort permanent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref
            .read(receiptNotifierProvider.notifier)
            .deleteReceipt(widget.existingReceipt!.id);

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          CustomSnackBar.showSuccess(context, 'Kvitto borttaget');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, 'Kunde inte ta bort kvitto: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user can add receipts (editing existing is always allowed)
    if (widget.existingReceipt == null &&
        !ReceiptLimitChecker.canAddReceipt(ref)) {
      return _buildLimitReachedScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Redigera kvitto' : 'Lägg till kvitto'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(6),
            children: [
              // Image preview/picker card
              Card(
                child: InkWell(
                  onTap: isEditMode ? null : _showImageSourcePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Beskrivning',
                          hintText: 'T.ex. "Oljebyte - Biltema"',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      // Date
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Välj datum',
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Belopp',
                          hintText: '2500',
                          suffixText: 'kr',
                          counterText: '',
                          prefixIcon: Icon(Icons.payments),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Delete button (edit mode only)
              if (isEditMode)
                OutlinedButton.icon(
                  onPressed: _deleteReceipt,
                  icon: const Icon(Icons.delete),
                  label: const Text('Ta bort'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                const SizedBox(height: 14),

              const SizedBox(height: 14),

              // Save button
              ElevatedButton(
                onPressed: _isUploading ? null : _saveReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            isEditMode ? 'Uppdatera' : 'Spara',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitReachedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uppgradera')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 100, color: Colors.blue),
              const SizedBox(height: 24),

              const Text(
                'Maxgräns',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Du har uppnått gränsen för antal sparade kvitton',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),

              const SizedBox(height: 32),

              // Benefits list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium ger dig:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefit('Obegränsat antal kvitton'),
                    _buildBenefit('Synkronisering mellan enheter'),
                    _buildBenefit('PDF-export med kvitton'),
                    _buildBenefit('Backup i molnet'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Upgrade button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaywallScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Uppgradera till Premium',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Avbryt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_imageFile!, fit: BoxFit.cover),
            if (!isEditMode)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Show existing receipt image if editing
    if (isEditMode && widget.existingReceipt != null) {
      return FutureBuilder<File?>(
        future: ref
            .read(receiptNotifierProvider.notifier)
            .getLocalFile(widget.existingReceipt!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(snapshot.data!, fit: BoxFit.cover),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    // Empty state - prompt to add image
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Lägg till kvitto',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ta foto eller välj från galleri',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'maj',
      'jun',
      'jul',
      'aug',
      'sep',
      'okt',
      'nov',
      'dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
