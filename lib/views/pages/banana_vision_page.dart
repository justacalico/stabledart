import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../services/settings_manager.dart';
import '../../state/image_lab_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../widgets/page_scaffold.dart';

class BananaVisionPage extends StatelessWidget {
  const BananaVisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ImageLabStore>();
    final settings = context.watch<SettingsManager>();
    return PageScaffold(
      title: 'Image Lab',
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => store.newConversation(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Chat'),
        ),
      ],
      child: settings.settings.geminiApiKey == null
          ? const _GeminiSetupNotice()
          : Row(
              children: [
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final c in store.conversations)
                        _ConversationTile(
                          conversation: c,
                          selected: c.id == store.currentId,
                        ),
                    ],
                  ),
                ),
                const Expanded(child: _ConversationView()),
              ],
            ),
    );
  }
}

class _GeminiSetupNotice extends StatelessWidget {
  const _GeminiSetupNotice();

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsManager>();
    final controller = TextEditingController();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.key, size: 40, color: AppColors.accent),
                const SizedBox(height: 16),
                const Text(
                  'Gemini API Setup Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Image Lab uses the Gemini API for conversational image '
                  'generation. Enter your API key to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      settings.update(
                        (s) => s.geminiApiKey = controller.text.trim(),
                      );
                    }
                  },
                  child: const Text('Save Key'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ImageLabConversation conversation;
  final bool selected;

  const _ConversationTile({required this.conversation, required this.selected});

  @override
  Widget build(BuildContext context) {
    final store = context.read<ImageLabStore>();
    return Material(
      color: selected ? AppColors.surfaceAlt : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => store.selectConversation(conversation.id),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '${conversation.messages.length} messages · ${timeAgo(conversation.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconSize: 16,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) {
                  if (v == 'rename') {
                    _renameDialog(context, store);
                  } else {
                    store.deleteConversation(conversation);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _renameDialog(BuildContext context, ImageLabStore store) {
    final controller = TextEditingController(text: conversation.title);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              store.renameConversation(conversation, controller.text.trim());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView();

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ImageLabStore>();
    final convo = store.current;
    return Column(
      children: [
        Expanded(
          child: convo == null
              ? const Center(
                  child: Text(
                    'Start a new chat to generate images with AI.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: convo.messages.length,
                  itemBuilder: (context, i) {
                    final m = convo.messages[i];
                    final isUser = m.role == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 480),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.accentDim
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.text, style: const TextStyle(fontSize: 13)),
                            if (m.imageUrls.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  height: 160,
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (store.isGenerating) const LinearProgressIndicator(minHeight: 2),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(
                    hintText: 'Describe an image to generate...',
                  ),
                  onSubmitted: (_) => _send(store),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: store.isGenerating ? null : () => _send(store),
                icon: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send(ImageLabStore store) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    store.send(text);
  }
}
