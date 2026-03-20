import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';

class EditInsuranceScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const EditInsuranceScreen({super.key, required this.vehicle});

  @override
  ConsumerState<EditInsuranceScreen> createState() =>
      _EditInsuranceScreenState();
}

class _EditInsuranceScreenState extends ConsumerState<EditInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _costController;
  late TextEditingController _policyNumberController;

  String? _selectedType;
  DateTime? _renewalDate;

  bool get _hasExistingInsurance => widget.vehicle.insuranceCompany != null;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(
      text: widget.vehicle.insuranceCompany,
    );
    _costController = TextEditingController(
      text: widget.vehicle.insuranceCostPerYear?.toStringAsFixed(0) ?? '',
    );
    _policyNumberController = TextEditingController(
      text: widget.vehicle.insurancePolicyNumber,
    );
    _selectedType = widget.vehicle.insuranceType;
    _renewalDate = widget.vehicle.insuranceRenewalDate;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _costController.dispose();
    _policyNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Försäkringsinformation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24),

            // Insurance company
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Försäkringsbolag',
                hintText: 'T.ex. Folksam, If, Länsförsäkringar',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Insurance type
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Försäkringstyp',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'comprehensive',
                  child: Text('Helförsäkring'),
                ),
                DropdownMenuItem(value: 'half', child: Text('Halvförsäkring')),
                DropdownMenuItem(
                  value: 'liability',
                  child: Text('Trafikförsäkring'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Cost per year
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Kostnad per år (kr)',
                hintText: 'T.ex. 8500',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
                suffixText: 'kr/år',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 16),

            // Renewal date
            /*             InkWell(
              onTap: _pickRenewalDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Förnyelsedatum',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _renewalDate != null
                      ? DateFormat('d MMMM yyyy', 'sv').format(_renewalDate!)
                      : 'Välj datum',
                  style: TextStyle(
                    color: _renewalDate != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ), 
            const SizedBox(height: 16),*/

            // Policy number
            TextFormField(
              controller: _policyNumberController,
              decoration: const InputDecoration(
                labelText: 'Försäkringsnummer (valfritt)',
                hintText: 'Ditt försäkringsnummer',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            if (_hasExistingInsurance)
              OutlinedButton.icon(
                onPressed: _clearInsurance,
                label: const Text('Ta bort försäkringsinformation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            if (_hasExistingInsurance) const SizedBox(height: 14),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    _hasExistingInsurance ? 'Uppdatera' : 'Spara',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  /*   Future<void> _pickRenewalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _renewalDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)), // 5 years
      locale: const Locale('sv'),
    );

    if (picked != null) {
      setState(() {
        _renewalDate = picked;
      });
    }
  } */

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedVehicle = widget.vehicle.copyWith(
      insuranceCompany: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      insuranceType: _selectedType,
      insuranceCostPerYear: _costController.text.isEmpty
          ? null
          : double.tryParse(_costController.text),
      insuranceRenewalDate: _renewalDate,
      insurancePolicyNumber: _policyNumberController.text.trim().isEmpty
          ? null
          : _policyNumberController.text.trim(),
    );

    await ref.read(vehicleRepositoryProvider).update(updatedVehicle);

    ref.invalidate(vehiclesProvider);

    if (mounted) {
      CustomSnackBar.showSuccess(context, 'Försäkringsinformation sparad');
      Navigator.pop(context);
    }
  }

  Future<void> _clearInsurance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort försäkring?'),
        content: const Text(
          'Är du säker på att du vill ta bort all försäkringsinformation?',
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

    if (confirmed == true) {
      await ref.read(vehicleRepositoryProvider).clearInsurance(widget.vehicle);

      ref.invalidate(vehiclesProvider);

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Försäkringsinformation borttagen');
        Navigator.pop(context);
      }
    }
  }
}
