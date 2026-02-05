import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:telephony/telephony.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:io';
import '../providers.dart';
import '../widgets/contact_list_widget.dart';
import '../widgets/number_input_widget.dart';
import '../widgets/sms_progress_widget.dart';
import '../services/permission_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final allRecipients = ref.watch(allRecipientsProvider);
    final message = ref.watch(messageProvider);
    final smsState = ref.watch(smsStateProvider);

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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          const SizedBox(height: 8),
                          const NumberInputWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ContactListWidget(),
                  ),
                ),
              ],
            ),
      floatingActionButton: allRecipients.isNotEmpty && message.isNotEmpty && !smsState.isSending
          ? FloatingActionButton.extended(
              onPressed: () => _showSendConfirmation(context, ref),
              icon: const Icon(Icons.send),
              label: Text(Platform.isIOS ? 'Open Messages' : 'Send SMS'),
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        await sendSMS(
          message: message,
          recipients: allRecipients,
        );

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