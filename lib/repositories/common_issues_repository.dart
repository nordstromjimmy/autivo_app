import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/common_inspection_issue.dart';

class CommonIssuesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active common inspection issues from Supabase
  /// Returns list sorted by sort_order
  Future<List<CommonInspectionIssue>> fetchCommonIssues() async {
    try {
      final response = await _supabase
          .from('common_inspection_issues')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CommonInspectionIssue.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch common issues: $e');
    }
  }

  /// Fetch issues by category
  Future<List<CommonInspectionIssue>> fetchIssuesByCategory(
    String category,
  ) async {
    try {
      final response = await _supabase
          .from('common_inspection_issues')
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CommonInspectionIssue.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch issues by category: $e');
    }
  }

  /// Fetch issues by severity
  Future<List<CommonInspectionIssue>> fetchIssuesBySeverity(
    String severity,
  ) async {
    try {
      final response = await _supabase
          .from('common_inspection_issues')
          .select()
          .eq('is_active', true)
          .eq('severity', severity)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CommonInspectionIssue.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch issues by severity: $e');
    }
  }
}
