import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/settings_manager.dart';

abstract class ImageLabProvider {
  Future<ImageLabMessage> respond(
    ImageLabConversation conversation,
    String prompt,
  );
}

class MockImageLabProvider implements ImageLabProvider {
  @override
  Future<ImageLabMessage> respond(
    ImageLabConversation conversation,
    String prompt,
  ) async => ImageLabMessage(
    id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
    role: 'assistant',
    text: 'Generated image for "$prompt"',
    imageUrls: ['image://generated/${conversation.messages.length}'],
    timestamp: DateTime.now(),
  );
}

class ImageLabStore extends ChangeNotifier {
  final SettingsManager _settings;
  final ImageLabProvider provider;
  final List<ImageLabConversation> _conversations = [];
  String? _currentId;
  bool _isGenerating = false;

  ImageLabStore(this._settings, {ImageLabProvider? provider})
    : provider = provider ?? MockImageLabProvider() {
    _load();
  }

  List<ImageLabConversation> get conversations =>
      List.unmodifiable(_conversations);
  String? get currentId => _currentId;
  bool get isGenerating => _isGenerating;

  ImageLabConversation? get current {
    for (final c in _conversations) {
      if (c.id == _currentId) return c;
    }
    return null;
  }

  void _load() {
    final raw = _settings.readRaw('conversations');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          _conversations.add(ImageLabConversation.fromJson(item));
        }
      }
      if (_conversations.isNotEmpty) _currentId = _conversations.first.id;
    } catch (_) {
      // corrupted store -> start fresh
    }
  }

  Future<void> _persist() => _settings.writeRaw(
    'conversations',
    jsonEncode(_conversations.map((c) => c.toJson()).toList()),
  );

  Future<ImageLabConversation> newConversation({
    String title = 'New Chat',
  }) async {
    final conversation = ImageLabConversation(
      id: 'conv-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
    );
    _conversations.insert(0, conversation);
    _currentId = conversation.id;
    await _persist();
    notifyListeners();
    return conversation;
  }

  void selectConversation(String id) {
    _currentId = id;
    notifyListeners();
  }

  Future<void> renameConversation(ImageLabConversation c, String title) async {
    c.title = title;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteConversation(ImageLabConversation c) async {
    _conversations.removeWhere((x) => x.id == c.id);
    if (_currentId == c.id) {
      _currentId = _conversations.isEmpty ? null : _conversations.first.id;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> send(String prompt) async {
    var convo = current;
    convo ??= await newConversation(title: prompt);
    convo.messages.add(
      ImageLabMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}-u',
        role: 'user',
        text: prompt,
        timestamp: DateTime.now(),
      ),
    );
    _isGenerating = true;
    notifyListeners();
    try {
      final reply = await provider.respond(convo, prompt);
      convo.messages.add(reply);
      if (convo.title == 'New Chat') convo.title = prompt;
    } finally {
      _isGenerating = false;
      await _persist();
      notifyListeners();
    }
  }
}
