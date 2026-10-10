class InstalledWorkflow {
  final String id;
  final String name;
  final String description;
  final String author;
  final String baseModel;
  final List<String> requiredNodes;
  final DateTime installedAt;

  const InstalledWorkflow({
    required this.id,
    required this.name,
    this.description = '',
    this.author = '',
    this.baseModel = '',
    this.requiredNodes = const [],
    required this.installedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'author': author,
    'baseModel': baseModel,
    'requiredNodes': requiredNodes,
    'installedAt': installedAt.toIso8601String(),
  };

  factory InstalledWorkflow.fromJson(Map<String, dynamic> json) =>
      InstalledWorkflow(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        author: json['author'] as String? ?? '',
        baseModel: json['baseModel'] as String? ?? '',
        requiredNodes: (json['requiredNodes'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        installedAt:
            DateTime.tryParse(json['installedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
