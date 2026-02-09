import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../widgets/checklist_item.dart';

class BesiktningChecklistScreen extends StatefulWidget {
  final Vehicle vehicle;

  const BesiktningChecklistScreen({super.key, required this.vehicle});

  @override
  State<BesiktningChecklistScreen> createState() =>
      _BesiktningChecklistScreenState();
}

class _BesiktningChecklistScreenState extends State<BesiktningChecklistScreen> {
  final Map<String, bool> _checkedItems = {};

  final List<Map<String, String>> _checklistItems = [
    {
      'title': 'Belysning',
      'description':
          'Kontrollera alla lampor (helljus, halvljus, blinkers, bromljus)',
    },
    {
      'title': 'Vindrutetorkare',
      'description': 'Kontrollera att torkarna fungerar och inte är slitna',
    },
    {
      'title': 'Däck',
      'description': 'Mönsterdjup minst 1,6 mm. Kontrollera på alla däck.',
    },
    {
      'title': 'Bromsar',
      'description': 'Kontrollera att bromsarna känns bra och inte vibrerar',
    },
    {
      'title': 'Spegel och glas',
      'description':
          'Inga sprickor i vindruta, backspeglar hela och justerbara',
    },
    {
      'title': 'Utsläpp',
      'description': 'Avgassystemet ska vara helt, inga läckage eller rost',
    },
    {
      'title': 'Oljor och vätskor',
      'description': 'Kontrollera motorolja, spolarvätska, kylvätska',
    },
    {
      'title': 'Registreringsskylt',
      'description': 'Skylten ska vara hel, ren och läsbar',
    },
    {
      'title': 'Varningstriangel',
      'description': 'Ska finnas i bilen och vara hel',
    },
    {
      'title': 'Säkerhetsbälten',
      'description': 'Alla bälten ska fungera och låsa ordentligt',
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var item in _checklistItems) {
      _checkedItems[item['title']!] = false;
    }
  }

  int get _checkedCount =>
      _checkedItems.values.where((checked) => checked).length;

  @override
  Widget build(BuildContext context) {
    final progress = _checkedCount / _checklistItems.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Besiktnings-checklista')),
      body: Column(
        children: [
          // Progress card
          Card(
            margin: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Framsteg',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '$_checkedCount/${_checklistItems.length}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  if (progress == 1.0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Alla punkter kontrollerade!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Checklist items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _checklistItems.length,
              itemBuilder: (context, index) {
                final item = _checklistItems[index];
                return ChecklistItem(
                  title: item['title']!,
                  description: item['description']!,
                  isChecked: _checkedItems[item['title']!]!,
                  onChanged: (value) {
                    setState(() {
                      _checkedItems[item['title']!] = value ?? false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
