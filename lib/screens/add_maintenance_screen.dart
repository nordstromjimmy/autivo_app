import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';

class AddMaintenanceScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final MaintenanceRecord?
  existingRecord; // null = add mode, not null = edit mode

  const AddMaintenanceScreen({
    super.key,
    required this.vehicleId,
    this.existingRecord,
  });

  @override
  ConsumerState<AddMaintenanceScreen> createState() =>
      _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends ConsumerState<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _locationController;

  late String _selectedType;
  late DateTime _selectedDate;

  final List<Map<String, dynamic>> _maintenanceTypes = [
    {'value': 'service', 'label': 'Service', 'icon': Icons.build},
    {'value': 'parts', 'label': 'Reservdel', 'icon': Icons.settings},
    /*     {'value': 'tire_change', 'label': 'Däckbyte', 'icon': Icons.album}, */
    {'value': 'besiktning', 'label': 'Besiktning', 'icon': Icons.verified},
    {'value': 'other', 'label': 'Annat', 'icon': Icons.description},
  ];

  bool get isEditMode => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if editing
    if (isEditMode) {
      final record = widget.existingRecord!;
      _descriptionController = TextEditingController(text: record.description);
      _mileageController = TextEditingController(
        text: record.mileage?.toString() ?? '',
      );
      _costController = TextEditingController(
        text: record.cost?.toString() ?? '',
      );
      _locationController = TextEditingController(text: record.location ?? '');
      _selectedType = record.type;
      _selectedDate = record.date;
    } else {
      _descriptionController = TextEditingController();
      _mileageController = TextEditingController();
      _costController = TextEditingController();
      _locationController = TextEditingController();
      _selectedType = 'service';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = MaintenanceRecord(
        id: isEditMode ? widget.existingRecord!.id : const Uuid().v4(),
        vehicleId: widget.vehicleId,
        date: _selectedDate,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        mileage: _mileageController.text.isNotEmpty
            ? int.tryParse(_mileageController.text)
            : null,
        cost: _costController.text.isNotEmpty
            ? double.tryParse(_costController.text)
            : null,
        location: _locationController.text.isNotEmpty
            ? _locationController.text.trim()
            : null,
        createdAt: isEditMode ? widget.existingRecord!.createdAt : null,
      );

      ref.read(maintenanceNotifierProvider.notifier).addRecord(record);
      Navigator.pop(context);

      // Clear any existing snackbars before showing new one
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Post uppdaterad' : 'Post tillagd'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort post?'),
        content: const Text('Denna åtgärd kan inte ångras.'),
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
          .read(maintenanceNotifierProvider.notifier)
          .deleteRecord(widget.existingRecord!.id);
      Navigator.pop(context);

      // Clear any existing snackbars before showing new one
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post borttagen'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Redigera service' : 'Lägg till service'),
        actions: isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: _deleteRecord,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selection
            Text(
              'Typ av service',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _maintenanceTypes.map((type) {
                final isSelected = _selectedType == type['value'];
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type['icon'] as IconData, size: 18),
                      const SizedBox(width: 4),
                      Text(type['label'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type['value'] as String;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivning *',
                hintText: 'T.ex. "Oljebyte och filter"',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ange beskrivning';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Datum',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Mileage
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Mätarställning',
                hintText: '15000',
                border: OutlineInputBorder(),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Plats/Verkstad',
                hintText: 'T.ex. "Biltema Stockholm"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Cost
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Kostnad',
                hintText: '2500',
                border: OutlineInputBorder(),
                suffixText: 'kr',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditMode ? 'Uppdatera' : 'Spara'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.year}';
  }
}
