import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';

class VehicleVerificationScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleVerificationScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifiera ägarskap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current status
          _buildCurrentStatus(context),

          const SizedBox(height: 24),

          // Verification options
          Text(
            'Verifieringsalternativ',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Option 1: Self-verification
          _buildVerificationOption(
            context,
            ref,
            level: 'self',
            icon: Icons.camera_alt,
            title: 'Själv-verifiering',
            description: 'Ladda upp foto på registreringsbevis',
            badge: '✓ Ägare',
            color: Colors.orange,
            isAvailable: true,
            onTap: () => _showSelfVerification(context, ref),
          ),

          const SizedBox(height: 12),

          // Option 2: SMS verification
          _buildVerificationOption(
            context,
            ref,
            level: 'sms',
            icon: Icons.sms,
            title: 'SMS-verifiering',
            description: 'Verifiera via SMS till Transportstyrelsen',
            badge: '✓ Verifierad',
            color: Colors.blue,
            isAvailable: true,
            onTap: () => _showSmsVerification(context, ref),
          ),

          const SizedBox(height: 12),

          // Option 3: Official verification (Premium)
          _buildVerificationOption(
            context,
            ref,
            level: 'official',
            icon: Icons.verified_user,
            title: 'Officiell verifiering',
            description: 'BankID + Transportstyrelsen API',
            badge: '✓ Officiellt Verifierad',
            color: Colors.green,
            isAvailable: false, // Premium feature
            isPremium: true,
            onTap: () => _showPremiumUpgrade(context),
          ),

          const SizedBox(height: 32),

          // Why verify section
          _buildWhyVerifySection(context),

          const SizedBox(height: 32),

          // Developer reset button
          if (vehicle.isVerified) _buildDeveloperResetSection(context, ref),
        ],
      ),
    );
  }

  // Add this new method
  Widget _buildDeveloperResetSection(BuildContext context, WidgetRef ref) {
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
              onPressed: () => _showResetConfirmation(context, ref),
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

  // Add this method
  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _resetVerification(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Nollställ'),
          ),
        ],
      ),
    );
  }

  // Add this method
  void _resetVerification(BuildContext context, WidgetRef ref) {
    final updatedVehicle = Vehicle(
      id: vehicle.id,
      registrationNumber: vehicle.registrationNumber,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      fuelType: vehicle.fuelType,
      engineSize: vehicle.engineSize,
      nextBesiktningDate: vehicle.nextBesiktningDate,
      createdAt: vehicle.createdAt,
      verificationLevel: 'none', // Reset to none
      verifiedAt: null, // Clear verified date
      verificationProof: null, // Clear proof
      isCurrentOwner: vehicle.isCurrentOwner,
      ownershipStartDate: vehicle.ownershipStartDate,
      ownershipEndDate: vehicle.ownershipEndDate,
    );

    ref.read(vehiclesProvider.notifier).updateVehicle(updatedVehicle);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifiering nollställd'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
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
                  vehicle.isVerified ? Icons.check_circle : Icons.info_outline,
                  color: vehicle.isVerified ? Colors.green : Colors.grey,
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
              vehicle.verificationBadge.isEmpty
                  ? 'Ej verifierad'
                  : vehicle.verificationBadge,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: vehicle.isVerified ? Colors.green : Colors.grey[600],
              ),
            ),
            if (vehicle.verifiedAt != null) ...[
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

  Widget _buildVerificationOption(
    BuildContext context,
    WidgetRef ref, {
    required String level,
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required Color color,
    required bool isAvailable,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    final isCurrentLevel = vehicle.verificationLevel == level;

    return Card(
      child: InkWell(
        onTap: isCurrentLevel ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentLevel ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isCurrentLevel ? Colors.white : color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentLevel)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (!isAvailable)
                const Icon(Icons.lock, color: Colors.grey)
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
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
            _buildBenefitItem('Låter dig överföra historik till ny ägare'),
            _buildBenefitItem('Får tillgång till verifierade PDF-rapporter'),
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

  void _showSelfVerification(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Själv-verifiering'),
        content: const Text(
          'Ladda upp ett foto på ditt registreringsbevis. '
          'Vi kommer kontrollera att registreringsnumret stämmer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement photo upload
              Navigator.pop(context);
              _verifyVehicle(context, ref, 'self');
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ta foto'),
          ),
        ],
      ),
    );
  }

  void _showSmsVerification(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS-verifiering'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Följ dessa steg:'),
            const SizedBox(height: 12),
            const Text('1. Skicka SMS med registreringsnummer till:'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '71640',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '2. Du får svar från Transportstyrelsen',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              '3. Ladda upp skärmdump av svaret här',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              'Kostnad: 3 kr via operatören',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement SMS verification
              Navigator.pop(context);
              _verifyVehicle(context, ref, 'sms');
            },
            icon: const Icon(Icons.upload),
            label: const Text('Ladda upp'),
          ),
        ],
      ),
    );
  }

  void _showPremiumUpgrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Premium-funktion'),
          ],
        ),
        content: const Text(
          'Officiell verifiering via BankID och Transportstyrelsen API '
          'är tillgänglig för Premium-användare.\n\n'
          'Uppgradera till Premium för att få tillgång till:\n'
          '• Officiell verifiering\n'
          '• API-uppslag av fordon\n'
          '• Obegränsat antal fordon\n'
          '• Avancerade rapporter',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanske senare'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to premium upgrade screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Uppgradera nu'),
          ),
        ],
      ),
    );
  }

  void _verifyVehicle(BuildContext context, WidgetRef ref, String level) {
    // Update vehicle verification
    final updatedVehicle = Vehicle(
      id: vehicle.id,
      registrationNumber: vehicle.registrationNumber,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      fuelType: vehicle.fuelType,
      engineSize: vehicle.engineSize,
      nextBesiktningDate: vehicle.nextBesiktningDate,
      createdAt: vehicle.createdAt,
      verificationLevel: level,
      verifiedAt: DateTime.now(),
      isCurrentOwner: vehicle.isCurrentOwner,
      ownershipStartDate: vehicle.ownershipStartDate,
    );

    ref.read(vehiclesProvider.notifier).updateVehicle(updatedVehicle);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fordon verifierat som $level'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.year}';
  }
}
