import 'dart:convert';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'services/permission_service.dart';
import 'models/sms_history.dart';
import 'models/sms_template.dart';

// Theme Provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

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

// Contacts Provider
final contactsProvider =
    NotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>(ContactsNotifier.new);

class ContactsNotifier extends Notifier<AsyncValue<List<Contact>>> {
  @override
  AsyncValue<List<Contact>> build() {
    loadContacts();
    return const AsyncValue.loading();
  }

  Future<void> loadContacts() async {
    try {
      if (await PermissionService.requestContactsPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        final contactsWithPhones =
            contacts.where((contact) => contact.phones.isNotEmpty).toList();
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
final selectedContactsProvider =
    NotifierProvider<SelectedContactsNotifier, List<Contact>>(SelectedContactsNotifier.new);

class SelectedContactsNotifier extends Notifier<List<Contact>> {
  @override
  List<Contact> build() => [];

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
final manualNumbersProvider =
    NotifierProvider<ManualNumbersNotifier, List<String>>(ManualNumbersNotifier.new);

class ManualNumbersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

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

  void removeNumbers(List<String> numbersToRemove) {
    state = state.where((number) => !numbersToRemove.contains(number)).toList();
  }

  List<String> _parseNumbers(String text) {
    final List<String> numbers = [];
    final RegExp phoneRegex = RegExp(r'[\+]?[0-9]{10,15}');
    final matches = phoneRegex.allMatches(text);
    final existingNormalized = state.map(normalizePhoneNumber).toSet();

    for (final match in matches) {
      final number = match.group(0);
      if (number != null) {
        final normalized = normalizePhoneNumber(number);
        if (!existingNormalized.contains(normalized)) {
          numbers.add(number);
          existingNormalized.add(normalized);
        }
      }
    }

    return numbers;
  }
}

// Message Provider
final messageProvider = NotifierProvider<MessageNotifier, String>(MessageNotifier.new);

class MessageNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateMessage(String message) {
    state = message;
  }

  void clearMessage() {
    state = '';
  }
}

// SMS Sending State Provider
final smsStateProvider = NotifierProvider<SmsStateNotifier, SmsState>(SmsStateNotifier.new);

class SmsState {
  final bool isSending;
  final bool isCancelled;
  final int totalCount;
  final int sentCount;
  final int failedCount;
  final List<String> failedNumbers;
  final String? error;

  const SmsState({
    this.isSending = false,
    this.isCancelled = false,
    this.totalCount = 0,
    this.sentCount = 0,
    this.failedCount = 0,
    this.failedNumbers = const [],
    this.error,
  });

  SmsState copyWith({
    bool? isSending,
    bool? isCancelled,
    int? totalCount,
    int? sentCount,
    int? failedCount,
    List<String>? failedNumbers,
    String? error,
  }) {
    return SmsState(
      isSending: isSending ?? this.isSending,
      isCancelled: isCancelled ?? this.isCancelled,
      totalCount: totalCount ?? this.totalCount,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      failedNumbers: failedNumbers ?? this.failedNumbers,
      error: error ?? this.error,
    );
  }
}

class SmsStateNotifier extends Notifier<SmsState> {
  @override
  SmsState build() => const SmsState();

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

  void cancelSending() {
    state = state.copyWith(isCancelled: true);
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

// Phone number normalization - strips spaces, dashes, parentheses for comparison
String normalizePhoneNumber(String number) {
  return number.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
}

// All Recipients Provider (combines contacts and manual numbers)
final allRecipientsProvider = Provider<List<String>>((ref) {
  final selectedContacts = ref.watch(selectedContactsProvider);
  final manualNumbers = ref.watch(manualNumbersProvider);

  final Map<String, String> seen = {}; // normalized -> original

  // Add contact numbers
  for (var contact in selectedContacts) {
    if (contact.phones.isNotEmpty) {
      final original = contact.phones.first.number;
      final normalized = normalizePhoneNumber(original);
      seen.putIfAbsent(normalized, () => original);
    }
  }

  // Add manual numbers
  for (var number in manualNumbers) {
    final normalized = normalizePhoneNumber(number);
    seen.putIfAbsent(normalized, () => number);
  }

  return seen.values.toList();
});

// SMS History Provider
final smsHistoryProvider =
    NotifierProvider<SmsHistoryNotifier, List<SmsHistoryEntry>>(SmsHistoryNotifier.new);

class SmsHistoryNotifier extends Notifier<List<SmsHistoryEntry>> {
  static const String _historyKey = 'sms_history';
  static const int _maxEntries = 100;

  @override
  List<SmsHistoryEntry> build() {
    _loadHistory();
    return [];
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      state = decoded.map((e) => SmsHistoryEntry.fromJson(e)).toList();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  void addEntry(SmsHistoryEntry entry) {
    state = [entry, ...state];
    if (state.length > _maxEntries) {
      state = state.sublist(0, _maxEntries);
    }
    _saveHistory();
  }

  void removeEntry(String id) {
    state = state.where((e) => e.id != id).toList();
    _saveHistory();
  }

  void clearHistory() {
    state = [];
    _saveHistory();
  }
}

// SMS Templates Provider
final smsTemplatesProvider =
    NotifierProvider<SmsTemplatesNotifier, List<SmsTemplate>>(SmsTemplatesNotifier.new);

class SmsTemplatesNotifier extends Notifier<List<SmsTemplate>> {
  static const String _templatesKey = 'sms_templates';

  @override
  List<SmsTemplate> build() {
    _loadTemplates();
    return [];
  }

  void _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getString(_templatesKey);
    if (templatesJson != null) {
      final List<dynamic> decoded = jsonDecode(templatesJson);
      state = decoded.map((e) => SmsTemplate.fromJson(e)).toList();
    }
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_templatesKey, encoded);
  }

  void addTemplate(SmsTemplate template) {
    state = [...state, template];
    _saveTemplates();
  }

  void updateTemplate(String id, {String? name, String? messageText}) {
    state = state.map((t) {
      if (t.id == id) return t.copyWith(name: name, messageText: messageText);
      return t;
    }).toList();
    _saveTemplates();
  }

  void removeTemplate(String id) {
    state = state.where((t) => t.id != id).toList();
    _saveTemplates();
  }
}
