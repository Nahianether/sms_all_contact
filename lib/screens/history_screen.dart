import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/sms_history.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(smsHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SMS History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed: () => _showClearConfirmation(context, ref),
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All History',
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No SMS history yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your sent messages will appear here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return _HistoryCard(
                  entry: entry,
                  onTap: () => _showDetailDialog(context, entry),
                  onDismiss: () {
                    ref
                        .read(smsHistoryProvider.notifier)
                        .removeEntry(entry.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Entry removed')),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_sweep,
            color: Theme.of(context).colorScheme.error, size: 32),
        title: const Text('Clear All History?'),
        content:
            const Text('This will permanently delete all SMS sending history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(smsHistoryProvider.notifier).clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, SmsHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _statusIcon(entry),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDate(entry.timestamp),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.messageText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _statRow(context, 'Recipients', '${entry.recipientCount}',
                  Icons.people, Theme.of(context).colorScheme.primary),
              _statRow(context, 'Sent', '${entry.sentCount}',
                  Icons.check_circle, Colors.green),
              _statRow(context, 'Failed', '${entry.failedCount}', Icons.error,
                  Colors.red),
              if (entry.wasCancelled)
                _statRow(context, 'Status', 'Cancelled', Icons.cancel,
                    Colors.orange),
              if (entry.failedNumbers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Failed Numbers',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 4),
                ...entry.failedNumbers.map(
                  (number) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      number,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  static Icon _statusIcon(SmsHistoryEntry entry) {
    if (entry.wasCancelled) {
      return const Icon(Icons.cancel, color: Colors.orange, size: 20);
    } else if (entry.failedCount > 0) {
      return const Icon(Icons.warning, color: Colors.red, size: 20);
    } else {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute';
  }
}

class _HistoryCard extends StatelessWidget {
  final SmsHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _HistoryCard({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(entry.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HistoryScreen._statusIcon(entry),
                      const SizedBox(width: 8),
                      Text(
                        HistoryScreen._formatDate(entry.timestamp),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.messageText.length > 60
                        ? '${entry.messageText.substring(0, 60)}...'
                        : entry.messageText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip(context, '${entry.recipientCount} recipients',
                          Theme.of(context).colorScheme.primaryContainer),
                      const SizedBox(width: 8),
                      _chip(context, '${entry.sentCount} sent',
                          Colors.green.withValues(alpha: 0.15)),
                      if (entry.failedCount > 0) ...[
                        const SizedBox(width: 8),
                        _chip(context, '${entry.failedCount} failed',
                            Colors.red.withValues(alpha: 0.15)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
