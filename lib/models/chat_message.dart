class ImageLabMessage {
  final String id;
  final String role;
  final String text;
  final List<String> imageUrls;
  final DateTime timestamp;

  const ImageLabMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.imageUrls = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'imageUrls': imageUrls,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ImageLabMessage.fromJson(Map<String, dynamic> json) =>
      ImageLabMessage(
        id: json['id'] as String,
        role: json['role'] as String? ?? 'user',
        text: json['text'] as String? ?? '',
        imageUrls: (json['imageUrls'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class ImageLabConversation {
  final String id;
  String title;
  String providerId;
  final List<ImageLabMessage> messages;
  final DateTime createdAt;

  ImageLabConversation({
    required this.id,
    required this.title,
    this.providerId = 'gemini',
    List<ImageLabMessage>? messages,
    DateTime? createdAt,
  }) : messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'providerId': providerId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ImageLabConversation.fromJson(Map<String, dynamic> json) =>
      ImageLabConversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        providerId: json['providerId'] as String? ?? 'gemini',
        messages: (json['messages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ImageLabMessage.fromJson)
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
