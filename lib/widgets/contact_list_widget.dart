import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../providers.dart';

class ContactListWidget extends ConsumerStatefulWidget {
  const ContactListWidget({super.key});

  @override
  ConsumerState<ContactListWidget> createState() => _ContactListWidgetState();
}

class _ContactListWidgetState extends ConsumerState<ContactListWidget> {
  String _searchQuery = '';

  List<Contact> _filterContacts(List<Contact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    final query = _searchQuery.toLowerCase();
    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number.toLowerCase()
          : '';
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () => ref
                            .read(selectedContactsProvider.notifier)
                            .toggleSelectAll(contacts),
                        child: Text(
                          selectedContacts.length == contacts.length
                              ? 'Deselect All'
                              : 'Select All',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            ref.read(contactsProvider.notifier).refreshContacts(),
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
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() => _searchQuery = ''),
                        icon: const Icon(Icons.clear, size: 20),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                final filtered = _filterContacts(contacts);
                if (contacts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contact_page, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No contacts with phone numbers found'),
                      ],
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No contacts match "$_searchQuery"'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
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
                                (contact.displayName.isNotEmpty
                                    ? contact.displayName[0].toUpperCase()
                                    : '?'),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName
                            : 'Unknown',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : 'No phone number',
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) => ref
                            .read(selectedContactsProvider.notifier)
                            .toggleContact(contact),
                      ),
                      onTap: () => ref
                          .read(selectedContactsProvider.notifier)
                          .toggleContact(contact),
                      selected: isSelected,
                    );
                  },
                );
              },
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
                      onPressed: () =>
                          ref.read(contactsProvider.notifier).refreshContacts(),
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
}
