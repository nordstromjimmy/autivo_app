class CommonInspectionIssue {
  final String id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String? preventionTip;
  final String? iconName;
  final int sortOrder;

  CommonInspectionIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.preventionTip,
    this.iconName,
    required this.sortOrder,
  });

  factory CommonInspectionIssue.fromMap(Map<String, dynamic> map) {
    return CommonInspectionIssue(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      severity: map['severity'] as String,
      preventionTip: map['prevention_tip'] as String?,
      iconName: map['icon_name'] as String?,
      sortOrder: map['sort_order'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'severity': severity,
      'prevention_tip': preventionTip,
      'icon_name': iconName,
      'sort_order': sortOrder,
    };
  }
}
