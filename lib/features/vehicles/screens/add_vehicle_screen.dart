import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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

      // Show appropriate success message
      if (mounted) {
        if (_nextBesiktningDate != null) {
          // Date is set - notification scheduled (or permission requested)
          final daysUntil = _nextBesiktningDate!
              .difference(DateTime.now())
              .inDays;

          if (daysUntil >= 30) {
            // Will get notification
            CustomSnackBar.showSuccess(
              context,
              isEditMode
                  ? 'Fordon uppdaterat! Påminnelse schemalagd 30 dagar innan besiktning.'
                  : 'Fordon tillagt! Påminnelse schemalagd 30 dagar innan besiktning.',
            );
          } else if (daysUntil > 0) {
            // Too soon for notification
            CustomSnackBar.showInfo(
              context,
              isEditMode
                  ? 'Fordon uppdaterat! Besiktningen är inom 30 dagar - ingen påminnelse schemalagd.'
                  : 'Fordon tillagt! Besiktningen är inom 30 dagar - ingen påminnelse schemalagd.',
            );
          } else {
            // Date in the past
            CustomSnackBar.showInfo(
              context,
              isEditMode
                  ? 'Fordon uppdaterat! Besiktningsdatumet har passerat.'
                  : 'Fordon tillagt! Besiktningsdatumet har passerat.',
            );
          }
        } else {
          // No date set - regular message
          CustomSnackBar.showSuccess(
            context,
            isEditMode ? 'Fordon uppdaterat' : 'Fordon tillagt',
          );
        }
      }
    }
  }

  // UPDATED: Block deletion of synced vehicles while offline
  void _deleteVehicle() async {
    final vehicle = widget.existingVehicle!;
    final isSignedIn = ref.read(isSignedInProvider);

    // Check if deletion will be blocked (synced vehicle + offline)
    if (vehicle.supabaseId != null && !isSignedIn) {
      CustomSnackBar.showError(
        context,
        'Du måste vara inloggad för att ta bort synkade fordon',
      );
      return; // Block deletion
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort fordon?'),
        content: const Text(
          'Detta kommer ta bort fordonet och all dess servicehistorik. Du kan ångra inom 3 sekunder.',
        ),
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
      // Delete the vehicle
      final notifier = ref.read(vehiclesNotifierProvider.notifier);
      final deleted = await notifier.deleteVehicle(vehicle.id);

      // Check if deletion succeeded
      if (!deleted && mounted) {
        // Deletion was blocked (shouldn't happen since we check above, but safety check)
        CustomSnackBar.showError(context, 'Kunde inte ta bort fordon');
        return;
      }

      // Successfully deleted - pop screen
      Navigator.of(context).pop();

      // Show SnackBar with undo
      ScaffoldMessenger.of(context).clearSnackBars();

      final messenger = ScaffoldMessenger.of(context);
      bool actionClicked = false;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Fordon borttaget'),
          action: SnackBarAction(
            label: 'Ångra',
            onPressed: () {
              actionClicked = true;
              // Re-add the vehicle
              notifier.addVehicle(vehicle);
              messenger.removeCurrentSnackBar();
            },
          ),
        ),
      );

      // Manually dismiss after 3 seconds if action wasn't clicked
      Future.delayed(const Duration(seconds: 3), () {
        if (!actionClicked) {
          messenger.removeCurrentSnackBar();
        }
      });
    }
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
