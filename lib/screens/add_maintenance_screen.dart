import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';
import '../utils/custom_snackbar.dart';

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
    {
      'value': 'service',
      'label': 'Service',
      'icon': Icons.build,
      'color': Colors.blue,
    },
    {
      'value': 'parts',
      'label': 'Reservdel',
      'icon': Icons.settings,
      'color': Colors.orange,
    },
    {
      'value': 'besiktning',
      'label': 'Besiktning',
      'icon': Icons.verified,
      'color': Colors.green,
    },
    {
      'value': 'other',
      'label': 'Annat',
      'icon': Icons.description,
      'color': Colors.brown,
    },
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
        text: record.cost?.toStringAsFixed(0) ?? '',
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
      final MaintenanceRecord record;

      if (isEditMode) {
        record = widget.existingRecord!.copyWith(
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
        );
      } else {
        record = MaintenanceRecord(
          id: const Uuid().v4(),
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
        );
      }

      // Save through provider
      if (isEditMode) {
        ref.read(maintenanceNotifierProvider.notifier).updateRecord(record);
      } else {
        ref.read(maintenanceNotifierProvider.notifier).addRecord(record);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).clearSnackBars();
      if (isEditMode) {
        CustomSnackBar.showSuccess(context, 'Post uppdaterad');
      } else {
        CustomSnackBar.showSuccess(context, 'Post tillagd');
      }
    }
  }

  void _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort post?'),
        content: const Text('Du kan ångra inom 3 sekunder.'),
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
      // Capture the notifier and deleted record
      final notifier = ref.read(maintenanceNotifierProvider.notifier);
      final deletedRecord = widget.existingRecord!;

      // Delete the record
      notifier.deleteRecord(deletedRecord.id);

      // Navigate back
      Navigator.pop(context);

      // Show SnackBar with undo on the previous screen
      ScaffoldMessenger.of(context).clearSnackBars();

      final messenger = ScaffoldMessenger.of(context);
      bool actionClicked = false;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Post borttagen'),
          action: SnackBarAction(
            label: 'Ångra',
            onPressed: () {
              actionClicked = true;
              // Re-add the record
              notifier.addRecord(deletedRecord);
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
      appBar: AppBar(title: Text(isEditMode ? 'Redigera' : 'Lägg till')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Type selection card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Typ av underhåll',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _maintenanceTypes.map((type) {
                          final isSelected = _selectedType == type['value'];
                          final color = type['color'] as Color;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = type['value'] as String;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.01),

                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? color : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type['icon'] as IconData,
                                    size: 20,
                                    color: isSelected
                                        ? color
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    type['label'] as String,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
                        decoration: const InputDecoration(
                          labelText: 'Beskrivning *',
                          hintText: 'T.ex. "Oljebyte och filter"',
                          prefixIcon: Icon(Icons.description),
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
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Datum',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(_selectedDate)),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Plats/Verkstad',
                          hintText: 'T.ex. "Biltema Stockholm"',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Numbers card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          // Mileage
                          TextFormField(
                            controller: _mileageController,
                            decoration: const InputDecoration(
                              labelText: 'Mätarställning',
                              hintText: '15000',
                              suffixText: 'km',
                              prefixIcon: Icon(Icons.speed),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Cost
                          TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'Kostnad',
                              hintText: '2500',
                              suffixText: 'kr',
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              isEditMode
                  ? OutlinedButton.icon(
                      onPressed: _deleteRecord,
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
                  : const SizedBox(height: 14),
              const SizedBox(height: 14),
              // Save button
              ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
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
