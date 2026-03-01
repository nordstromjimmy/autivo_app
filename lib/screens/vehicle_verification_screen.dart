import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../services/verification_service.dart';
import '../services/photo_service.dart';
import '../utils/custom_snackbar.dart';

class VehicleVerificationScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const VehicleVerificationScreen({super.key, required this.vehicle});

  @override
  ConsumerState<VehicleVerificationScreen> createState() =>
      _VehicleVerificationScreenState();
}

class _VehicleVerificationScreenState
    extends ConsumerState<VehicleVerificationScreen> {
  final VerificationService _verificationService = VerificationService();
  final PhotoService _photoService = PhotoService(); // Add separate instance
  File? _verificationPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationPhoto();
  }

  Future<void> _loadVerificationPhoto() async {
    if (widget.vehicle.verificationProof != null) {
      final file = File(widget.vehicle.verificationProof!);
      if (await file.exists()) {
        setState(() {
          _verificationPhoto = file;
        });
      }
    }
  }

  @override
  void dispose() {
    _verificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifiera ägarskap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current status
          _buildCurrentStatus(context),

          const SizedBox(height: 24),

          // Verification option
          Text(
            'Verifiering',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Self-verification option
          _buildVerificationOption(context),

          const SizedBox(height: 24),

          // Show verification photo if exists
          if (_verificationPhoto != null) _buildVerificationPhotoCard(),

          const SizedBox(height: 24),

          // Why verify section
          _buildWhyVerifySection(context),

          const SizedBox(height: 32),

          // Developer reset button
          if (widget.vehicle.isVerified) _buildDeveloperResetSection(context),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.vehicle.isVerified
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: widget.vehicle.isVerified ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nuvarande status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.vehicle.verificationBadge.isEmpty
                  ? 'Ej verifierad'
                  : widget.vehicle.verificationBadge,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.vehicle.isVerified
                    ? Colors.green
                    : Colors.grey[600],
              ),
            ),
            if (widget.vehicle.isVerified &&
                widget.vehicle.verifiedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Verifierad ${_formatDate(widget.vehicle.verifiedAt!)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationOption(BuildContext context) {
    final isVerified = widget.vehicle.isVerified;

    return Card(
      child: InkWell(
        onTap: isVerified ? null : () => _showVerificationOptions(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: isVerified ? Colors.white : Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Själv-verifiering',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ladda upp foto på registreringsbevis',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✓ Ägare',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationPhotoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uppladdat registreringsbevis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeletePhotoConfirmation(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _verificationPhoto!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tryck på papperskorgen för att ta bort och verifiera igen',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyVerifySection(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Varför verifiera?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBenefitItem('Ökar värdet på din bil vid försäljning'),
            _buildBenefitItem('Bygger förtroende hos köpare'),
            _buildBenefitItem('Bevis på äkthet vid export av historik'),
            _buildBenefitItem('Visar att du är den riktiga ägaren'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperResetSection(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Utvecklarverktyg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Nollställ verifiering för att testa verifieringsflödet igen.',
              style: TextStyle(fontSize: 13, color: Colors.red[800]),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showResetConfirmation(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Nollställ verifiering'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red[300]!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === ACTIONS ===

  void _showVerificationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ta foto'),
              subtitle: const Text('Använd kameran'),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto(useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Välj från galleri'),
              subtitle: const Text('Välj befintligt foto'),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto(useCamera: false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto({required bool useCamera}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get photo using local PhotoService instance
      File? photoFile;
      if (useCamera) {
        photoFile = await _photoService.takePicture();
      } else {
        photoFile = await _photoService.pickFromGallery();
      }

      if (photoFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Show processing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyserar registreringsbevis...'),
                    SizedBox(height: 8),
                    Text(
                      'Detta kan ta några sekunder',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Verify the document
      final result = await _verificationService.verifyVehicle(
        widget.vehicle,
        photoFile,
      );

      // Close processing dialog
      if (mounted) Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });

      // Show result
      if (result.success) {
        _showVerificationSuccess(result);
      } else {
        _showVerificationFailure(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        CustomSnackBar.showError(context, 'Ett fel uppstod: $e');
      }
    }
  }

  void _showVerificationSuccess(VerificationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Verifierad!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registreringsbeviset är giltigt!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Show verification count
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '3/3 verifieringar lyckades',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveVerification(result);
            },
            child: const Text('Godkänn verifiering'),
          ),
        ],
      ),
    );
  }

  void _showVerificationFailure(VerificationResult result) {
    final doc = result.documentVerification;

    // Count successful verifications
    int successCount = 0;
    if (doc != null) {
      if (doc.registrationNumberFound) successCount++;
      if (doc.hasRegistreringsbevis) successCount++;
      if (doc.hasTransportstyrelsen) successCount++;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Kunde inte verifiera'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$successCount/3 verifieringar lyckades',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verifiering misslyckades',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'För att verifiera fordonet måste alla 3 verifieringar lyckas.',
                    style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Se till att hela dokumentet syns tydligt\n'
                    '• Undvik skuggor och reflektioner\n'
                    '• Ha bra ljusförhållanden\n'
                    '• Håll kameran rakt mot dokumentet',
                    style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _capturePhoto(useCamera: true);
            },
            child: const Text('Försök igen'),
          ),
        ],
      ),
    );
  }

  void _saveVerification(VerificationResult result) {
    final updatedVehicle = widget.vehicle.copyWith(
      verificationLevel: 'self',
      verifiedAt: DateTime.now(),
      verificationProof: result.photoPath,
      verificationConfidence: result.confidenceScore,
    );

    ref.read(vehiclesProvider.notifier).updateVehicle(updatedVehicle);

    setState(() {
      _verificationPhoto = File(result.photoPath!);
    });

    CustomSnackBar.showSuccess(context, 'Fordon verifierat!');
  }

  void _showDeletePhotoConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort verifiering?'),
        content: const Text(
          'Detta kommer ta bort fotot och återställa fordonet till overifierat läge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVerification();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVerification() async {
    await _verificationService.deleteVerification(widget.vehicle.id);

    final updatedVehicle = widget.vehicle.copyWith(
      verificationLevel: 'none',
      verifiedAt: null,
      verificationProof: null,
      verificationConfidence: null,
    );

    ref.read(vehiclesProvider.notifier).updateVehicle(updatedVehicle);

    setState(() {
      _verificationPhoto = null;
    });

    if (mounted) {
      CustomSnackBar.showInfo(context, 'Verifiering borttagen');
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Nollställ verifiering?'),
          ],
        ),
        content: const Text(
          'Detta kommer ta bort verifieringsstatus och återställa fordonet till overifierat läge.\n\n'
          'Detta är endast för utveckling och testning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVerification();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Nollställ'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.year}';
  }
}
