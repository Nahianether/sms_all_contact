import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:io';
import '../providers.dart';
import '../widgets/contact_picker_sheet.dart';
import '../widgets/selected_contacts_chips.dart';
import '../widgets/number_input_widget.dart';
import '../widgets/sms_progress_widget.dart';
import '../widgets/template_selector_widget.dart';
import '../services/permission_service.dart';
import '../models/sms_history.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.checkAndRequestInitialPermissions(context);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildStep(BuildContext context, String number, String text, bool done) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          child: Center(
            child: done
                ? Icon(Icons.check, size: 14, color: Theme.of(context).colorScheme.onPrimary)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _openContactPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ContactPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRecipients = ref.watch(allRecipientsProvider);
    final message = ref.watch(messageProvider);
    final smsState = ref.watch(smsStateProvider);

    // Listen for resend trigger from history screen
    ref.listen<String?>(resendTriggerProvider, (previous, next) {
      if (next != null) {
        _messageController.text = next;
        ref.read(resendTriggerProvider.notifier).clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Bulk SMS Sender',
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              speed: const Duration(milliseconds: 100),
            ),
          ],
          isRepeatingAnimation: false,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: smsState.isSending
          ? const SmsProgressWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // How to use guide
                  if (allRecipients.isEmpty || message.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Card(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How to send',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildStep(context, '1', 'Add recipients via contacts or paste numbers', allRecipients.isNotEmpty),
                              const SizedBox(height: 4),
                              _buildStep(context, '2', 'Type your message below', message.isNotEmpty),
                              const SizedBox(height: 4),
                              _buildStep(context, '3', Platform.isIOS ? 'Tap "Open Messages" button to send' : 'Tap "Send SMS" button to send', false),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Recipients section (TOP)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recipients',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Chip(
                                  label: Text('${allRecipients.length}'),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openContactPicker(context),
                                icon: const Icon(Icons.contacts),
                                label: const Text('Select Contacts'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SelectedContactsChips(),
                            const SizedBox(height: 8),
                            const NumberInputWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Message section (BOTTOM)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TemplateSelectorWidget(messageController: _messageController),
                            TextField(
                              controller: _messageController,
                              onChanged: (value) => ref.read(messageProvider.notifier).updateMessage(value),
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Type your message here...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Characters: ${message.length}/160${message.length > 160 ? ' (${(message.length / 160).ceil()} SMS parts)' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: message.length > 160
                                    ? Theme.of(context).colorScheme.error
                                    : message.length > 140
                                        ? Colors.orange
                                        : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
      bottomNavigationBar: allRecipients.isNotEmpty && message.isNotEmpty && !smsState.isSending
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: FilledButton.icon(
                onPressed: () => _showSendConfirmation(context, ref),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  Platform.isIOS
                      ? 'Open Messages (${allRecipients.length})'
                      : 'Send SMS (${allRecipients.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showSendConfirmation(BuildContext context, WidgetRef ref) {
    final allRecipients = ref.read(allRecipientsProvider);
    final message = ref.read(messageProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.send, size: 32),
        title: const Text('Confirm Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send SMS to ${allRecipients.length} recipient${allRecipients.length > 1 ? 's' : ''}?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.length > 100 ? '${message.substring(0, 100)}...' : message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (message.length > 160) ...[
              const SizedBox(height: 8),
              Text(
                'This message will be sent as ${(message.length / 160).ceil()} SMS parts per recipient.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendSMS(context, ref);
            },
            child: Text('Send to ${allRecipients.length}'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSMS(BuildContext context, WidgetRef ref) async {
    final allRecipients = ref.read(allRecipientsProvider);
    final message = ref.read(messageProvider);

    if (allRecipients.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add recipients and enter message')),
      );
      return;
    }

    // Start sending process
    ref.read(smsStateProvider.notifier).startSending(allRecipients.length);

    if (Platform.isIOS) {
      try {
        final recipientsStr = allRecipients.join(',');
        final uri = Uri(
          scheme: 'sms',
          path: recipientsStr,
          queryParameters: {'body': message},
        );
        await launchUrl(uri);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Messages app. You must send each message manually.'),
              duration: Duration(seconds: 4),
            ),
          );

          // Clear fields on iOS since user will handle sending
          _messageController.clear();
          ref.read(messageProvider.notifier).clearMessage();
          ref.read(selectedContactsProvider.notifier).clearContacts();
          ref.read(manualNumbersProvider.notifier).clearNumbers();
        }
      } catch (e) {
        ref.read(smsStateProvider.notifier).setError('Error opening Messages: $e');
      }
    } else {
      // Android SMS sending with retry logic
      await _sendAndroidSMS(context, ref, allRecipients, message);
    }

    // Save to history
    final finalState = ref.read(smsStateProvider);
    ref.read(smsHistoryProvider.notifier).addEntry(
          SmsHistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            messageText: message,
            recipientCount: allRecipients.length,
            sentCount: finalState.sentCount,
            failedCount: finalState.failedCount,
            failedNumbers: List<String>.from(finalState.failedNumbers),
            recipientNumbers: List<String>.from(allRecipients),
            wasCancelled: finalState.isCancelled,
          ),
        );

    ref.read(smsStateProvider.notifier).completeSending();
  }

  Future<void> _sendAndroidSMS(
    BuildContext context,
    WidgetRef ref,
    List<String> recipients,
    String message,
  ) async {
    // Check all required permissions
    if (!await PermissionService.requestSmsPermission()) {
      ref.read(smsStateProvider.notifier).setError('SMS permission denied');
      return;
    }

    if (!await PermissionService.requestPhonePermission()) {
      ref.read(smsStateProvider.notifier).setError('Phone permission denied');
      return;
    }

    int sentCount = 0;
    List<String> failedNumbers = [];
    final telephony = Telephony.instance;

    for (String number in recipients) {
      // Check if user cancelled
      if (ref.read(smsStateProvider).isCancelled) {
        break;
      }

      bool success = false;
      int retries = 0;
      const maxRetries = 3;

      while (!success && retries < maxRetries) {
        // Check cancel inside retry loop too
        if (ref.read(smsStateProvider).isCancelled) break;

        try {
          await telephony.sendSms(
            to: number,
            message: message,
          );
          success = true;
          sentCount++;
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            failedNumbers.add(number);
          } else {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      ref.read(smsStateProvider.notifier).updateProgress(
        sentCount,
        failedNumbers.length,
        failedNumbers,
      );

      // Delay between messages to avoid carrier rate limiting
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (context.mounted) {
      final wasCancelled = ref.read(smsStateProvider).isCancelled;

      if (wasCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sending cancelled. $sentCount sent, ${recipients.length - sentCount - failedNumbers.length} skipped.'),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (failedNumbers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All $sentCount messages sent successfully!')),
        );

        // Clear all fields on complete success
        _messageController.clear();
        ref.read(messageProvider.notifier).clearMessage();
        ref.read(selectedContactsProvider.notifier).clearContacts();
        ref.read(manualNumbersProvider.notifier).clearNumbers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$sentCount sent, ${failedNumbers.length} failed. Failed numbers preserved for retry.'),
            duration: const Duration(seconds: 4),
          ),
        );

        // Remove only successful numbers, keep failed ones
        final successfulNumbers = recipients.where((number) => !failedNumbers.contains(number)).toList();
        ref.read(manualNumbersProvider.notifier).removeNumbers(successfulNumbers);
      }
    }
  }
}