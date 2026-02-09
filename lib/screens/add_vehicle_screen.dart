import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../utils/constants.dart';

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

  String? _selectedFuelType;
  DateTime? _nextBesiktningDate;

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
      _selectedFuelType = vehicle.fuelType;
      _nextBesiktningDate = vehicle.nextBesiktningDate;
    } else {
      _regNumberController = TextEditingController();
      _makeController = TextEditingController();
      _modelController = TextEditingController();
      _yearController = TextEditingController();
      _engineSizeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _engineSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
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

  void _saveVehicle() {
    if (_formKey.currentState!.validate() && _nextBesiktningDate != null) {
      final vehicle = Vehicle(
        id: isEditMode ? widget.existingVehicle!.id : const Uuid().v4(),
        registrationNumber: _regNumberController.text.toUpperCase().trim(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        fuelType: _selectedFuelType,
        engineSize: _engineSizeController.text.isNotEmpty
            ? _engineSizeController.text.trim()
            : null,
        nextBesiktningDate: _nextBesiktningDate!,
        createdAt: isEditMode
            ? widget.existingVehicle!.createdAt
            : null, // Preserve original createdAt when editing
      );

      if (isEditMode) {
        ref.read(vehiclesProvider.notifier).updateVehicle(vehicle);
      } else {
        ref.read(vehiclesProvider.notifier).addVehicle(vehicle);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Fordon uppdaterat' : 'Fordon tillagt'),
        ),
      );
    }
  }

  void _deleteVehicle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort fordon?'),
        content: const Text(
          'Detta kommer permanent ta bort fordonet och all dess servicehistorik. Denna åtgärd kan inte ångras.',
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
      ref
          .read(vehiclesProvider.notifier)
          .deleteVehicle(widget.existingVehicle!.id);
      // Pop twice - once for dialog, once for edit screen, once for details screen
      Navigator.pop(context); // Close edit screen
      Navigator.pop(context); // Close details screen
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fordon borttaget')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Redigera fordon' : 'Lägg till fordon'),
        /*         actions: isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: _deleteVehicle,
                ),
              ]
            : null, */
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _regNumberController,
              decoration: const InputDecoration(
                labelText: 'Registreringsnummer *',
                hintText: 'ABC123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              textCapitalization: TextCapitalization.characters,
              enabled:
                  !isEditMode, // Don't allow changing reg number when editing
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

            TextFormField(
              controller: _makeController,
              decoration: const InputDecoration(
                labelText: 'Märke *',
                hintText: 'Volvo',
                border: OutlineInputBorder(),
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

            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Modell *',
                hintText: 'V70',
                border: OutlineInputBorder(),
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

            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Årsmodell *',
                hintText: '2015',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedFuelType,
              decoration: const InputDecoration(
                labelText: 'Bränsle',
                border: OutlineInputBorder(),
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

            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Nästa besiktning *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  errorText:
                      _nextBesiktningDate == null &&
                          _formKey.currentState?.validate() == false
                      ? 'Välj datum'
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _nextBesiktningDate == null
                          ? 'Välj datum'
                          : '${_nextBesiktningDate!.day}/${_nextBesiktningDate!.month} ${_nextBesiktningDate!.year}',
                      style: TextStyle(
                        color: _nextBesiktningDate == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveVehicle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditMode ? 'Uppdatera fordon' : 'Spara fordon'),
            ),

            if (isEditMode) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _deleteVehicle,
                icon: const Icon(Icons.delete),
                label: const Text('Ta bort fordon'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
