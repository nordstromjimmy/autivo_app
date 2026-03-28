import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../receipts/providers/receipt_provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../../auth/providers/auth_provider.dart'; // ← ADD THIS IMPORT
import '../../../core/config/constants.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle? existingVehicle; // null = add mode, not null = edit mode

  const AddVehicleScreen({super.key, this.existingVehicle});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _regNumberController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _engineSizeController;
  late final TextEditingController _mileageController;

  String? _selectedFuelType;
  DateTime? _nextBesiktningDate;
  DateTime? _ownershipStartDate;

  bool get isEditMode => widget.existingVehicle != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if editing
    if (isEditMode) {
      final vehicle = widget.existingVehicle!;
      _regNumberController = TextEditingController(
        text: vehicle.registrationNumber,
      );
      _makeController = TextEditingController(text: vehicle.make);
      _modelController = TextEditingController(text: vehicle.model);
      _yearController = TextEditingController(text: vehicle.year.toString());
      _engineSizeController = TextEditingController(
        text: vehicle.engineSize ?? '',
      );
      _mileageController = TextEditingController(
        text: vehicle.currentMileage?.toString() ?? '',
      );
      _selectedFuelType = vehicle.fuelType;
      _nextBesiktningDate = vehicle.nextBesiktningDate;
      _ownershipStartDate = vehicle.ownershipStartDate;
    } else {
      _regNumberController = TextEditingController();
      _makeController = TextEditingController();
      _modelController = TextEditingController();
      _yearController = TextEditingController();
      _engineSizeController = TextEditingController();
      _mileageController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _engineSizeController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectBesiktningDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _nextBesiktningDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        _nextBesiktningDate = date;
      });
    }
  }

  Future<void> _selectOwnershipDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _ownershipStartDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _ownershipStartDate = date;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      final Vehicle vehicle;

      if (isEditMode) {
        // EDIT MODE: Use copyWith (preserves verification!)
        vehicle = widget.existingVehicle!.copyWith(
          registrationNumber: _regNumberController.text.toUpperCase().trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text),
          fuelType: _selectedFuelType,
          engineSize: _engineSizeController.text.isNotEmpty
              ? _engineSizeController.text.trim()
              : null,
          currentMileage: _mileageController.text.isNotEmpty
              ? int.tryParse(_mileageController.text)
              : null,
          nextBesiktningDate: _nextBesiktningDate,
          ownershipStartDate: _ownershipStartDate,
        );
      } else {
        // ADD MODE: Create new vehicle (no verification yet)
        vehicle = Vehicle(
          id: const Uuid().v4(),
          registrationNumber: _regNumberController.text.toUpperCase().trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text),
          fuelType: _selectedFuelType,
          engineSize: _engineSizeController.text.isNotEmpty
              ? _engineSizeController.text.trim()
              : null,
          currentMileage: _mileageController.text.isNotEmpty
              ? int.tryParse(_mileageController.text)
              : null,
          nextBesiktningDate: _nextBesiktningDate,
          ownershipStartDate: _ownershipStartDate,
        );
      }

      // Save the vehicle
      if (isEditMode) {
        await ref
            .read(vehiclesNotifierProvider.notifier)
            .updateVehicle(vehicle);
      } else {
        await ref.read(vehiclesNotifierProvider.notifier).addVehicle(vehicle);
      }

      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          isEditMode ? 'Fordon uppdaterat' : 'Fordon tillagt',
        );
      }
    }
  }

  Future<void> _deleteVehicle() async {
    final vehicle = widget.existingVehicle!;
    final isSignedIn = ref.read(isSignedInProvider);

    // Check if deletion will be blocked (synced vehicle + offline)
    if (vehicle.supabaseId != null && !isSignedIn) {
      CustomSnackBar.showError(
        context,
        'Du måste vara inloggad för att ta bort synkade fordon',
      );
      return;
    }

    // Count related data
    final maintenanceRecords = ref.read(maintenanceProvider(vehicle.id));
    final receipts = ref.read(receiptsForVehicleProvider(vehicle.id));
    final maintenanceCount = maintenanceRecords.length;
    final receiptCount = receipts.length;

    // Show detailed confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            SizedBox(width: 8),
            Expanded(child: Text('Ta bort fordon?')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detta kommer att radera:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              _buildDeleteItem(
                Icons.directions_car,
                'Fordon',
                vehicle.registrationNumber,
                Colors.blue,
              ),
              if (maintenanceCount > 0)
                _buildDeleteItem(
                  Icons.build,
                  'Serviceposter',
                  '$maintenanceCount st',
                  Colors.orange,
                ),
              if (receiptCount > 0)
                _buildDeleteItem(
                  Icons.receipt_long,
                  'Kvitton (inkl. bilder)',
                  '$receiptCount st',
                  Colors.green,
                ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Denna åtgärd kan INTE ångras!',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Radera allt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Raderar fordon och relaterad data...'),
                    SizedBox(height: 8),
                    Text(
                      'Detta kan ta en stund',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {
      // Delete vehicle (cascade delete)
      final deleted = await ref
          .read(vehiclesNotifierProvider.notifier)
          .deleteVehicle(vehicle.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (!deleted) {
        // Deletion failed
        if (mounted) {
          CustomSnackBar.showError(context, 'Kunde inte radera fordon');
        }
        return;
      }

      // Pop edit screen first, THEN navigate home
      if (mounted) {
        // Pop the edit screen
        Navigator.pop(context);

        // Small delay to allow UI to settle
        await Future.delayed(Duration(milliseconds: 100));

        // Then navigate to home
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Show success message
          CustomSnackBar.showSuccess(
            context,
            'Fordon och all relaterad data raderad',
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        CustomSnackBar.showError(context, 'Fel vid radering: ${e.toString()}');
      }
    }
  }

  Widget _buildDeleteItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.close, color: Colors.red, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Redigera fordon' : 'Lägg till fordon'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Registration number
              TextFormField(
                controller: _regNumberController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Registreringsnummer *',
                  hintText: 'ABC123',
                  counterText: '',
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: !isEditMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ange registreringsnummer';
                  }
                  return null;
                },
              ),
              if (isEditMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Registreringsnummer kan inte ändras',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                "Obligatoriska uppgifter",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              // Make
              TextFormField(
                controller: _makeController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Märke *',
                  hintText: 'Volvo',
                  counterText: '',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ange bilmärke';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Model
              TextFormField(
                controller: _modelController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Modell *',
                  hintText: 'V70',
                  counterText: '',
                  prefixIcon: Icon(Icons.car_crash),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ange modell';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Year
              TextFormField(
                controller: _yearController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Årsmodell *',
                  hintText: '2015',
                  counterText: '',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ange årsmodell';
                  }
                  final year = int.tryParse(value);
                  if (year == null ||
                      year < 1900 ||
                      year > DateTime.now().year + 1) {
                    return 'Ange giltigt år';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Valfria uppgifter",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              // Fuel type
              DropdownButtonFormField<String>(
                initialValue: _selectedFuelType,
                decoration: const InputDecoration(
                  labelText: 'Bränsle',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                items: AppConstants.fuelTypes.map((fuel) {
                  return DropdownMenuItem(value: fuel, child: Text(fuel));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFuelType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Current mileage
              TextFormField(
                controller: _mileageController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Nuvarande mätarställning',
                  hintText: '150000',
                  suffixText: 'km',
                  counterText: '',
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Ownership start date
              InkWell(
                onTap: _selectOwnershipDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ägare sedan',
                    prefixIcon: Icon(Icons.person),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _ownershipStartDate == null
                            ? 'Välj datum (valfritt)'
                            : '${_ownershipStartDate!.day}/${_ownershipStartDate!.month} ${_ownershipStartDate!.year}',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Next besiktning date
              InkWell(
                onTap: _selectBesiktningDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Nästa besiktning',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _nextBesiktningDate == null
                            ? 'Välj datum (valfritt)'
                            : '${_nextBesiktningDate!.day}/${_nextBesiktningDate!.month} ${_nextBesiktningDate!.year}',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delete button (only in edit mode)
              if (isEditMode) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _deleteVehicle,
                  icon: const Icon(Icons.delete),
                  label: const Text('Ta bort fordon'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Save button
              ElevatedButton(
                onPressed: _saveVehicle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEditMode ? 'Uppdatera fordon' : 'Spara fordon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
