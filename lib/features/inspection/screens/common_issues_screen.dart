import 'package:flutter/material.dart';
import '../models/common_inspection_issue.dart';
import '../repositories/common_issues_repository.dart';

class CommonIssuesScreen extends StatefulWidget {
  const CommonIssuesScreen({super.key});

  @override
  State<CommonIssuesScreen> createState() => _CommonIssuesScreenState();
}

class _CommonIssuesScreenState extends State<CommonIssuesScreen> {
  final CommonIssuesRepository _repository = CommonIssuesRepository();
  List<CommonInspectionIssue> _issues = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _repository.fetchCommonIssues();
      setState(() {
        _issues = issues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vanliga fel vid besiktning'),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : _buildIssuesList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Kunde inte ladda data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kontrollera din internetanslutning',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadIssues();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Försök igen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    if (_issues.isEmpty) {
      return const Center(child: Text('Inga fel hittades'));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          ..._issues.map((issue) => _buildIssueCard(issue)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Besiktningsstatistik 2024',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Var tredje bil (33,5%) hade brister vid besiktningen. Här är de vanligaste felen baserat på officiell statistik från Bilprovningen och Transportstyrelsen.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(CommonInspectionIssue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _getSeverityIcon(issue.severity),
          title: Text(
            issue.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _getCategoryLabel(issue.category),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (issue.preventionTip != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips för att undvika',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  issue.preventionTip!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSeverityIcon(String severity) {
    switch (severity) {
      case 'high':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error, color: Colors.red[700], size: 24),
        );
      case 'medium':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning, color: Colors.orange[700], size: 24),
        );
      case 'low':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.info, color: Colors.blue[700], size: 24),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.help, color: Colors.grey[700], size: 24),
        );
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'lights':
        return 'Belysning';
      case 'brakes':
        return 'Bromsar';
      case 'tires':
        return 'Däck';
      case 'emissions':
        return 'Miljö/Utsläpp';
      case 'windshield':
        return 'Vindruta';
      case 'steering':
        return 'Styrning';
      case 'other':
        return 'Övrigt';
      default:
        return category;
    }
  }
}
