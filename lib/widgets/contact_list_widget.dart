import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
import '../providers.dart';

class ContactListWidget extends ConsumerWidget {
  const ContactListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final selectedContacts = ref.watch(selectedContactsProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.contact_page,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contacts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                contactsAsync.when(
                  data: (contacts) => Row(
                    children: [
                      TextButton(
                        onPressed: () => _toggleSelectAll(ref, contacts),
                        child: Text(
                          selectedContacts.length == contacts.length 
                              ? 'Deselect All' 
                              : 'Select All',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => ref.read(contactsProvider.notifier).refreshContacts(),
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Contacts',
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) => contacts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contact_page, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No contacts with phone numbers found'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final isSelected = selectedContacts.contains(contact);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: isSelected
                                ? Icon(
                                    Icons.check, 
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  )
                                : Text(
                                    (contact.displayName?.isNotEmpty == true 
                                        ? contact.displayName![0].toUpperCase()
                                        : '?'),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            contact.displayName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            contact.phones?.isNotEmpty == true 
                                ? contact.phones!.first.value! 
                                : 'No phone number',
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) => _toggleContact(ref, contact),
                          ),
                          onTap: () => _toggleContact(ref, contact),
                          selected: isSelected,
                        );
                      },
                    ),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading contacts...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(contactsProvider.notifier).refreshContacts(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(WidgetRef ref, List<Contact> allContacts) {
    ref.read(selectedContactsProvider.notifier).toggleSelectAll(allContacts);
  }

  void _toggleContact(WidgetRef ref, Contact contact) {
    ref.read(selectedContactsProvider.notifier).toggleContact(contact);
  }
}