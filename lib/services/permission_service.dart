import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestAllPermissions(BuildContext context) async {
    final List<Permission> permissions = [
      Permission.contacts,
      Permission.sms,
    ];

    // Add Android-specific permissions
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.phone,
        Permission.storage,
      ]);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    List<Permission> deniedPermissions = [];
    statuses.forEach((permission, status) {
      if (status != PermissionStatus.granted) {
        deniedPermissions.add(permission);
      }
    });

    if (deniedPermissions.isNotEmpty && context.mounted) {
      _showPermissionDialog(context, deniedPermissions);
      return false;
    }

    return true;
  }

  static Future<bool> checkContactsPermission() async {
    return await Permission.contacts.isGranted;
  }

  static Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkPhonePermission() async {
    if (Platform.isIOS) return true; // iOS doesn't need phone permission
    return await Permission.phone.isGranted;
  }

  static Future<bool> requestPhonePermission() async {
    if (Platform.isIOS) return true; // iOS doesn't need phone permission
    final status = await Permission.phone.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkStoragePermission() async {
    if (Platform.isIOS) return true; // iOS handles storage differently
    return await Permission.storage.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) return true; // iOS handles storage differently
    final status = await Permission.storage.request();
    return status == PermissionStatus.granted;
  }

  static void _showPermissionDialog(BuildContext context, List<Permission> deniedPermissions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Permissions Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app requires the following permissions to function properly:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ...deniedPermissions.map((permission) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_getPermissionIcon(permission), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPermissionDescription(permission),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Please grant these permissions in the app settings.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.contacts:
        return Icons.contacts;
      case Permission.sms:
        return Icons.sms;
      case Permission.phone:
        return Icons.phone;
      case Permission.storage:
        return Icons.storage;
      default:
        return Icons.security;
    }
  }

  static String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.contacts:
        return 'Access contacts to select recipients';
      case Permission.sms:
        return 'Send SMS messages to selected contacts';
      case Permission.phone:
        return 'Access phone features for SMS sending';
      case Permission.storage:
        return 'Store app preferences and data';
      default:
        return 'Required for app functionality';
    }
  }

  static Future<void> checkAndRequestInitialPermissions(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    bool contactsGranted = await checkContactsPermission();
    bool smsGranted = await checkSmsPermission();
    
    if (!contactsGranted || !smsGranted) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Welcome!'),
              content: const Text(
                'To get started, this app needs permission to access your contacts and send SMS messages. '
                'This allows you to select contacts and send bulk messages.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    requestAllPermissions(context);
                  },
                  child: const Text('Grant Permissions'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}