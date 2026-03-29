import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/models/vehicle.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../../core/services/external/verification_service.dart';
import '../../../core/services/media/photo_service.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';
import '../../premium/utils/feature_checker.dart';
import '../../auth/screens/sign_up_screen.dart';

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
  final PhotoService _photoService = PhotoService();

  @override
  void dispose() {
    _verificationService.dispose();
    super.dispose();
  }

  /// Returns the up-to-date vehicle from the provider,
  /// falling back to the passed-in vehicle if it's been removed.
  Vehicle get _currentVehicle {
    return ref
        .watch(vehiclesProvider)
        .firstWhere(
          (v) => v.id == widget.vehicle.id,
          orElse: () => widget.vehicle,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _currentVehicle;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifiera ägarskap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentStatus(context, vehicle),
          const SizedBox(height: 24),
          Text(
            'Verifiering',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildVerificationOption(context, vehicle),
          const SizedBox(height: 24),
          if (vehicle.isVerified) _buildVerificationStatusCard(vehicle),
          const SizedBox(height: 24),
          _buildWhyVerifySection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(BuildContext context, Vehicle vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuvarande status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.isVerified ? vehicle.verificationBadge : 'Ej verifierad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: vehicle.isVerified ? Colors.green : Colors.grey[600],
              ),
            ),
            if (vehicle.isVerified && vehicle.verifiedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Verifierad ${_formatDate(vehicle.verifiedAt!)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationOption(BuildContext context, Vehicle vehicle) {
    final isVerified = vehicle.isVerified;
    final canVerify = ref.watch(featureCheckerProvider).hasAccount;

    return Card(
      child: InkWell(
        onTap: isVerified
            ? null
            : () {
                if (!canVerify) {
                  _showAccountRequiredDialog(context);
                  return;
                }
                _showVerificationOptions(context);
              },
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
                      : Colors.orange.withValues(alpha: 0.1),
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
                    if (!canVerify && !isVerified) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kräver konto',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isVerified)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (!canVerify)
                Icon(Icons.lock, color: Colors.orange[700])
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStatusCard(Vehicle vehicle) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verifierad med bild',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registreringsbevis har verifierats',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Återställ verifiering',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyVerifySection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Varför verifiera?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue[300] : Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBenefitItem('Ökar värdet på din bil vid försäljning', isDark),
            _buildBenefitItem('Bygger förtroende hos köpare', isDark),
            _buildBenefitItem('Bevis på äkthet vid export av historik', isDark),
            _buildBenefitItem('Visar att du är den riktiga ägaren', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: isDark ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.blue[200] : Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === ACTIONS ===

  void _showAccountRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Konto krävs'),
          ],
        ),
        content: const Text(
          'För att verifiera ditt fordon behöver du ett konto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: const Text('Skapa konto'),
          ),
        ],
      ),
    );
  }

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
                _captureAndVerify(useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Välj från galleri'),
              subtitle: const Text('Välj befintligt foto'),
              onTap: () {
                Navigator.pop(context);
                _captureAndVerify(useCamera: false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndVerify({required bool useCamera}) async {
    final photoFile = useCamera
        ? await _photoService.takePicture()
        : await _photoService.pickFromGallery();

    if (photoFile == null || !mounted) return;

    // Show processing dialog
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

    try {
      final result = await _verificationService.verifyVehicle(
        widget.vehicle,
        photoFile,
      );

      if (mounted) Navigator.pop(context); // Close processing dialog

      if (result.success) {
        _showVerificationSuccess(result);
      } else {
        _showVerificationFailure(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close processing dialog
        CustomSnackBar.showError(context, 'Ett fel uppstod: $e');
      }
    }
  }

  void _showVerificationSuccess(VerificationResult result) {
    /*     final doc = result.documentVerification!;
    final successCount = [
      doc.registrationNumberFound,
      doc.hasRegistreringsbevis,
      doc.hasTransportstyrelsen,
    ].where((c) => c).length; */

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text('Verifierad!', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verifieringen lyckades!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              /*             Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$successCount/3 verifieringar lyckades',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ), */
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveVerification(result);
              },
              child: const Text('Godkänn'),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationFailure(VerificationResult result) {
    final doc = result.documentVerification;
    final successCount = doc == null
        ? 0
        : [
            doc.registrationNumberFound,
            doc.hasRegistreringsbevis,
            doc.hasTransportstyrelsen,
          ].where((c) => c).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Kunde inte verifiera')),
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
                    'Alla 3 verifieringar måste lyckas för att godkänna dokumentet.',
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
              _captureAndVerify(useCamera: true);
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

    ref.read(vehiclesNotifierProvider.notifier).updateVehicle(updatedVehicle);
    CustomSnackBar.showSuccess(context, 'Fordon verifierat!');
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Återställ verifiering?'),
        content: const Text(
          'Detta tar bort verifieringen och återställer fordonet till overifierat läge.',
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
            child: const Text('Återställ'),
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

    ref.read(vehiclesNotifierProvider.notifier).updateVehicle(updatedVehicle);

    if (mounted) {
      CustomSnackBar.showInfo(context, 'Verifiering återställd');
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month} ${date.year}';
}
