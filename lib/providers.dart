import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'services/permission_service.dart';

// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    state = ThemeMode.values[themeIndex];
  }

  void setTheme(ThemeMode theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
}

// SIM Card Provider
class SimCardInfo {
  final String displayName;
  final int subscriptionId;
  final String carrierName;
  
  SimCardInfo({
    required this.displayName,
    required this.subscriptionId,
    required this.carrierName,
  });
}

final simCardsProvider = FutureProvider<List<SimCardInfo>>((ref) async {
  try {
    // For now, return default SIM. Telephony package has limited SIM support
    // In a real implementation, you'd check for dual SIM capability
    return [
      SimCardInfo(
        displayName: 'Default SIM',
        subscriptionId: -1,
        carrierName: 'Default',
      ),
    ];
  } catch (e) {
    return [];
  }
});

final selectedSimProvider = StateNotifierProvider<SelectedSimNotifier, SimCardInfo?>((ref) {
  return SelectedSimNotifier();
});

class SelectedSimNotifier extends StateNotifier<SimCardInfo?> {
  SelectedSimNotifier() : super(null);

  void selectSim(SimCardInfo? sim) {
    state = sim;
  }
}

// Contacts Provider
final contactsProvider = StateNotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>((ref) {
  return ContactsNotifier();
});

class ContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  ContactsNotifier() : super(const AsyncValue.loading()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      if (await PermissionService.requestContactsPermission()) {
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

// Selected Contacts Provider
final selectedContactsProvider = StateNotifierProvider<SelectedContactsNotifier, List<Contact>>((ref) {
  return SelectedContactsNotifier();
});

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

  void clearContacts() {
    state = [];
  }
}

// Manual Numbers Provider
final manualNumbersProvider = StateNotifierProvider<ManualNumbersNotifier, List<String>>((ref) {
  return ManualNumbersNotifier();
});

class ManualNumbersNotifier extends StateNotifier<List<String>> {
  ManualNumbersNotifier() : super([]);

  void addNumbers(String numbersText) {
    final numbers = _parseNumbers(numbersText);
    state = [...state, ...numbers];
  }

  void removeNumber(String number) {
    state = state.where((n) => n != number).toList();
  }

  void clearNumbers() {
    state = [];
  }

  void removeFailedNumbers(List<String> failedNumbers) {
    state = state.where((number) => !failedNumbers.contains(number)).toList();
  }

  List<String> _parseNumbers(String text) {
    final List<String> numbers = [];
    final RegExp phoneRegex = RegExp(r'[\+]?[0-9]{10,15}');
    final matches = phoneRegex.allMatches(text);
    
    for (final match in matches) {
      final number = match.group(0);
      if (number != null && !state.contains(number)) {
        numbers.add(number);
      }
    }
    
    return numbers;
  }
}

// Message Provider
final messageProvider = StateNotifierProvider<MessageNotifier, String>((ref) {
  return MessageNotifier();
});

class MessageNotifier extends StateNotifier<String> {
  MessageNotifier() : super('');

  void updateMessage(String message) {
    state = message;
  }

  void clearMessage() {
    state = '';
  }
}

// SMS Sending State Provider
final smsStateProvider = StateNotifierProvider<SmsStateNotifier, SmsState>((ref) {
  return SmsStateNotifier();
});

class SmsState {
  final bool isSending;
  final int totalCount;
  final int sentCount;
  final int failedCount;
  final List<String> failedNumbers;
  final String? error;

  const SmsState({
    this.isSending = false,
    this.totalCount = 0,
    this.sentCount = 0,
    this.failedCount = 0,
    this.failedNumbers = const [],
    this.error,
  });

  SmsState copyWith({
    bool? isSending,
    int? totalCount,
    int? sentCount,
    int? failedCount,
    List<String>? failedNumbers,
    String? error,
  }) {
    return SmsState(
      isSending: isSending ?? this.isSending,
      totalCount: totalCount ?? this.totalCount,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      failedNumbers: failedNumbers ?? this.failedNumbers,
      error: error ?? this.error,
    );
  }
}

class SmsStateNotifier extends StateNotifier<SmsState> {
  SmsStateNotifier() : super(const SmsState());

  void startSending(int totalCount) {
    state = SmsState(
      isSending: true,
      totalCount: totalCount,
      sentCount: 0,
      failedCount: 0,
      failedNumbers: [],
    );
  }

  void updateProgress(int sentCount, int failedCount, List<String> failedNumbers) {
    state = state.copyWith(
      sentCount: sentCount,
      failedCount: failedCount,
      failedNumbers: failedNumbers,
    );
  }

  void completeSending() {
    state = state.copyWith(isSending: false);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isSending: false);
  }

  void resetState() {
    state = const SmsState();
  }
}

// All Recipients Provider (combines contacts and manual numbers)
final allRecipientsProvider = Provider<List<String>>((ref) {
  final selectedContacts = ref.watch(selectedContactsProvider);
  final manualNumbers = ref.watch(manualNumbersProvider);
  
  List<String> allNumbers = [];
  
  // Add contact numbers
  for (var contact in selectedContacts) {
    if (contact.phones != null && contact.phones!.isNotEmpty) {
      allNumbers.add(contact.phones!.first.value!);
    }
  }
  
  // Add manual numbers
  allNumbers.addAll(manualNumbers);
  
  // Remove duplicates
  return allNumbers.toSet().toList();
});