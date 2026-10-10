class HuggingFaceModel {
  final String id;
  final String author;
  final String name;
  final String? pipelineTag;
  final List<String> tags;
  final int downloads;
  final int likes;
  final DateTime? lastModified;

  const HuggingFaceModel({
    required this.id,
    this.author = '',
    this.name = '',
    this.pipelineTag,
    this.tags = const [],
    this.downloads = 0,
    this.likes = 0,
    this.lastModified,
  });

  factory HuggingFaceModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['modelId'] as String? ?? '';
    final slash = id.indexOf('/');
    return HuggingFaceModel(
      id: id,
      author: slash > 0 ? id.substring(0, slash) : '',
      name: slash > 0 ? id.substring(slash + 1) : id,
      pipelineTag: json['pipeline_tag'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? ''),
    );
  }
}

class HuggingFaceFile {
  final String path;
  final int size;
  final String? lfsOid;

  const HuggingFaceFile({required this.path, this.size = 0, this.lfsOid});

  factory HuggingFaceFile.fromJson(Map<String, dynamic> json) =>
      HuggingFaceFile(
        path: json['path'] as String? ?? json['rfilename'] as String? ?? '',
        size:
            (json['size'] as num?)?.toInt() ??
            (json['lfs'] is Map<String, dynamic>
                ? ((json['lfs'] as Map<String, dynamic>)['size'] as num?)
                          ?.toInt() ??
                      0
                : 0),
        lfsOid: json['lfs'] is Map<String, dynamic>
            ? (json['lfs'] as Map<String, dynamic>)['oid'] as String?
            : null,
      );
}
