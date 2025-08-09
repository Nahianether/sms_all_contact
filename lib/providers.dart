import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final contactsProvider = StateNotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>((ref) {
  return ContactsNotifier();
});

final selectedContactsProvider = StateNotifierProvider<SelectedContactsNotifier, List<Contact>>((ref) {
  return SelectedContactsNotifier();
});

final messageProvider = StateNotifierProvider<MessageNotifier, String>((ref) {
  return MessageNotifier();
});

class ContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  ContactsNotifier() : super(const AsyncValue.loading()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contacts = await ContactsService.getContacts();
        final contactsWithPhones = contacts
            .where((contact) => contact.phones != null && contact.phones!.isNotEmpty)
            .toList();
        state = AsyncValue.data(contactsWithPhones);
      } else {
        state = AsyncValue.error('Contacts permission denied', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshContacts() async {
    state = const AsyncValue.loading();
    await loadContacts();
  }
}

class SelectedContactsNotifier extends StateNotifier<List<Contact>> {
  SelectedContactsNotifier() : super([]);

  void toggleContact(Contact contact) {
    if (state.contains(contact)) {
      state = state.where((c) => c != contact).toList();
    } else {
      state = [...state, contact];
    }
  }

  void selectAll(List<Contact> allContacts) {
    state = List.from(allContacts);
  }

  void deselectAll() {
    state = [];
  }

  void toggleSelectAll(List<Contact> allContacts) {
    if (state.length == allContacts.length) {
      deselectAll();
    } else {
      selectAll(allContacts);
    }
  }
}

class MessageNotifier extends StateNotifier<String> {
  MessageNotifier() : super('');

  void updateMessage(String message) {
    state = message;
  }

  void clearMessage() {
    state = '';
  }
}