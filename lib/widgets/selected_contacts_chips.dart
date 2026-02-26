import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class SelectedContactsChips extends ConsumerWidget {
  const SelectedContactsChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedContacts = ref.watch(selectedContactsProvider);

    if (selectedContacts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'From Contacts (${selectedContacts.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  ref.read(selectedContactsProvider.notifier).clearContacts(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: selectedContacts.map((contact) {
                final name = contact.displayName.isNotEmpty
                    ? contact.displayName
                    : (contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : 'Unknown');
                return Chip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => ref
                      .read(selectedContactsProvider.notifier)
                      .toggleContact(contact),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
