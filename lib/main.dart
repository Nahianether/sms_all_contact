import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS All Contacts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SMSHomePage(),
    );
  }
}

class SMSHomePage extends ConsumerWidget {
  const SMSHomePage({super.key});

  void _toggleSelectAll(WidgetRef ref, List<Contact> allContacts) {
    ref.read(selectedContactsProvider.notifier).toggleSelectAll(allContacts);
  }

  void _toggleContact(WidgetRef ref, Contact contact) {
    ref.read(selectedContactsProvider.notifier).toggleContact(contact);
  }

  Future<void> _sendSMS(BuildContext context, WidgetRef ref) async {
    final selectedContacts = ref.read(selectedContactsProvider);
    final message = ref.read(messageProvider);

    if (selectedContacts.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select contacts and enter message')),
      );
      return;
    }

    List<String> phoneNumbers = [];
    for (var contact in selectedContacts) {
      if (contact.phones != null && contact.phones!.isNotEmpty) {
        phoneNumbers.add(contact.phones!.first.value!);
      }
    }

    if (Platform.isIOS) {
      // iOS: Open native Messages app (user must manually send)
      try {
        await sendSMS(
          message: message,
          recipients: phoneNumbers,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Messages app. You must tap Send manually for each message.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening Messages: $e')),
          );
        }
      }
    } else {
      // Android: Direct SMS sending
      if (await Permission.sms.request().isGranted) {
        try {
          await sendSMS(
            message: message,
            recipients: phoneNumbers,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('SMS sent to ${phoneNumbers.length} contacts')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sending SMS: $e')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS permission denied')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final selectedContacts = ref.watch(selectedContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS All Contacts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => ref.read(messageProvider.notifier).updateMessage(value),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your message here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          contactsAsync.when(
            data: (contacts) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Contacts (${selectedContacts.length}/${contacts.length} selected)'),
                  ),
                  TextButton(
                    onPressed: () => _toggleSelectAll(ref, contacts),
                    child: Text(selectedContacts.length == contacts.length ? 'Deselect All' : 'Select All'),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading contacts: $error'),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) => ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final isSelected = selectedContacts.contains(contact);
                  
                  return ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) => _toggleContact(ref, contact),
                    ),
                    title: Text(contact.displayName ?? 'Unknown'),
                    subtitle: Text(
                      contact.phones?.isNotEmpty == true 
                          ? contact.phones!.first.value! 
                          : 'No phone number',
                    ),
                    onTap: () => _toggleContact(ref, contact),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sendSMS(context, ref),
        icon: const Icon(Icons.send),
        label: Text(Platform.isIOS ? 'Open Messages' : 'Send SMS'),
      ),
    );
  }
}
