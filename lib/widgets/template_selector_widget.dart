import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/sms_template.dart';

class TemplateSelectorWidget extends ConsumerWidget {
  final TextEditingController messageController;

  const TemplateSelectorWidget({
    super.key,
    required this.messageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(smsTemplatesProvider);
    final currentMessage = ref.watch(messageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Templates',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (currentMessage.isNotEmpty)
              TextButton.icon(
                onPressed: () =>
                    _showSaveTemplateDialog(context, ref, currentMessage),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        if (templates.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final template = templates[index];
                return GestureDetector(
                  onLongPress: () =>
                      _showTemplateOptions(context, ref, template),
                  child: ActionChip(
                    label: Text(template.name),
                    onPressed: () {
                      messageController.text = template.messageText;
                      ref
                          .read(messageProvider.notifier)
                          .updateMessage(template.messageText);
                    },
                  ),
                );
              },
            ),
          ),
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Write a message and tap Save to create a template.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _showSaveTemplateDialog(
      BuildContext context, WidgetRef ref, String messageText) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Holiday Greeting',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                messageText.length > 80
                    ? '${messageText.substring(0, 80)}...'
                    : messageText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(smsTemplatesProvider.notifier).addTemplate(
                    SmsTemplate(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      messageText: messageText,
                      createdAt: DateTime.now(),
                    ),
                  );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Template "$name" saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTemplateOptions(
      BuildContext context, WidgetRef ref, SmsTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                template.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditTemplateDialog(context, ref, template);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Delete Template',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(smsTemplatesProvider.notifier).removeTemplate(template.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template "${template.name}" deleted')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditTemplateDialog(
      BuildContext context, WidgetRef ref, SmsTemplate template) {
    final nameController = TextEditingController(text: template.name);
    final messageEditController =
        TextEditingController(text: template.messageText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageEditController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final msg = messageEditController.text.trim();
              if (name.isEmpty || msg.isEmpty) return;
              ref.read(smsTemplatesProvider.notifier).updateTemplate(
                    template.id,
                    name: name,
                    messageText: msg,
                  );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
