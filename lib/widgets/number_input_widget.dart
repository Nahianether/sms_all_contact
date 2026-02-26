import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class NumberInputWidget extends ConsumerStatefulWidget {
  const NumberInputWidget({super.key});

  @override
  ConsumerState<NumberInputWidget> createState() => _NumberInputWidgetState();
}

class _NumberInputWidgetState extends ConsumerState<NumberInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manualNumbers = ref.watch(manualNumbersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Paste numbers here (e.g., +1234567890)',
            border: const OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    onPressed: _clearInput,
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Clear Input',
                  )
                : null,
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (_) => _addNumbers(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _controller.text.isNotEmpty ? _addNumbers : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Numbers'),
          ),
        ),
        if (manualNumbers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Manual Numbers (${manualNumbers.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref.read(manualNumbersProvider.notifier).clearNumbers(),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: manualNumbers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final number = manualNumbers[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.phone, size: 16),
                    title: Text(
                      number,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    trailing: IconButton(
                      onPressed: () => ref.read(manualNumbersProvider.notifier).removeNumber(number),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Tip: Paste numbers in any format — comma-separated, one per line, or even consecutive (e.g., 016877229620171234567). 11-digit and +880 numbers are auto-detected.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _addNumbers() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final count = ref.read(manualNumbersProvider.notifier).addNumbers(text);
      _controller.clear();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '$count number${count > 1 ? 's' : ''} added'
              : 'No valid numbers found'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearInput() {
    _controller.clear();
    setState(() {});
  }
}