# SMS All Contacts

A Flutter mobile application that allows users to send SMS messages to all or selected contacts from their phone's contact list.

## Features

- 📱 **Contact Selection**: Browse and select contacts from your device's contact list
- ✅ **Bulk Selection**: Select all or individual contacts with checkboxes
- 💬 **Custom Messages**: Compose custom SMS messages
- 📲 **Cross-Platform SMS**: 
  - **Android**: Direct SMS sending with proper permissions
  - **iOS**: Opens native Messages app (requires manual send)
- 🔒 **Permission Handling**: Automatic permission requests for contacts and SMS
- 📊 **Contact Counter**: Shows selected vs total contact count
- ⚡ **State Management**: Uses Riverpod for efficient state management

## Screenshots

*Add screenshots of your app here*

## Requirements

- Flutter SDK ^3.8.1
- Dart SDK
- Android/iOS device or emulator
- Contacts and SMS permissions

## Dependencies

- `flutter_riverpod` - State management
- `contacts_service` - Access device contacts
- `flutter_sms` - SMS functionality
- `permission_handler` - Handle device permissions

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd sms_all_contact
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Permissions

### Android
The app requires the following permissions in `android/app/src/main/AndroidManifest.xml`:
- `READ_CONTACTS` - To access contacts
- `SEND_SMS` - To send SMS messages

### iOS
The app requires the following permissions in `ios/Runner/Info.plist`:
- `NSContactsUsageDescription` - To access contacts
- Note: iOS doesn't allow direct SMS sending, so the app opens the native Messages app

## How to Use

1. **Launch the app** - Grant necessary permissions when prompted
2. **Type your message** - Enter the SMS text in the message field
3. **Select contacts** - Choose individual contacts or use "Select All"
4. **Send SMS**:
   - **Android**: Tap "Send SMS" to send directly
   - **iOS**: Tap "Open Messages" to open Messages app (manual send required)

## Platform Differences

| Feature | Android | iOS |
|---------|---------|-----|
| SMS Sending | Direct/Automatic | Manual via Messages app |
| Permission Required | SMS + Contacts | Contacts only |
| User Action | Tap once to send | Tap send for each message |

## Project Structure

```
lib/
├── main.dart          # Main app entry point and UI
└── providers.dart     # Riverpod providers for state management
```

## Development

### Adding Features
1. Create new providers in `providers.dart`
2. Update UI components in `main.dart`
3. Test on both Android and iOS devices

### Testing
```bash
flutter test
```

### Building
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both platforms
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check Flutter documentation for platform-specific behavior

## Changelog

### v1.0.0
- Initial release
- Contact selection and SMS sending
- Cross-platform support (Android/iOS)
- Permission handling