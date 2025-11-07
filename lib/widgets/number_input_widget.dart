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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Paste numbers here (e.g., +1234567890, +0987654321)',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _controller.text.isNotEmpty ? _addNumbers : null,
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Numbers',
                      ),
                      IconButton(
                        onPressed: _controller.text.isNotEmpty ? _clearInput : null,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear Input',
                      ),
                    ],
                  ),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ],
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
          'Tip: You can paste multiple numbers separated by spaces, commas, or new lines. The app will automatically detect valid phone numbers.',
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
      ref.read(manualNumbersProvider.notifier).addNumbers(text);
      _controller.clear();
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numbers added successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearInput() {
    _controller.clear();
    setState(() {});
  }
}