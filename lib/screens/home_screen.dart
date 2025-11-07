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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.checkAndRequestInitialPermissions(context);
    });
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
        actions: [
          IconButton(
            onPressed: () => _showSimSelection(context, ref),
            icon: const Icon(Icons.sim_card),
            tooltip: 'Select SIM',
          ),
        ],
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
                            onChanged: (value) => ref.read(messageProvider.notifier).updateMessage(value),
                            maxLines: 4,
                            maxLength: 160,
                            decoration: const InputDecoration(
                              hintText: 'Type your message here...',
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Characters: ${message.length}/160',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: message.length > 160 
                                  ? Theme.of(context).colorScheme.error 
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
              onPressed: () => _sendSMS(context, ref),
              icon: const Icon(Icons.send),
              label: Text(Platform.isIOS ? 'Open Messages' : 'Send SMS'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  void _showSimSelection(BuildContext context, WidgetRef ref) async {
    final simCardsAsync = ref.read(simCardsProvider);
    
    simCardsAsync.when(
      data: (simCards) {
        if (simCards.length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only one SIM card detected')),
          );
          return;
        }
        
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select SIM Card',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...simCards.map((sim) => ListTile(
                  leading: const Icon(Icons.sim_card),
                  title: Text(sim.displayName),
                  subtitle: Text(sim.carrierName),
                  onTap: () {
                    ref.read(selectedSimProvider.notifier).selectSim(sim);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
      loading: () {},
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading SIM cards: $error')),
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
    String message
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
      bool success = false;
      int retries = 0;
      const maxRetries = 3;

      while (!success && retries < maxRetries) {
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
        failedNumbers
      );

      // Small delay between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (context.mounted) {
      if (failedNumbers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All $sentCount messages sent successfully!')),
        );
        
        // Clear all fields on complete success
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
        ref.read(manualNumbersProvider.notifier).removeFailedNumbers(
          recipients.where((number) => !failedNumbers.contains(number)).toList()
        );
      }
    }
  }
}