class SmsHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String messageText;
  final int recipientCount;
  final int sentCount;
  final int failedCount;
  final List<String> failedNumbers;
  final bool wasCancelled;

  const SmsHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.messageText,
    required this.recipientCount,
    required this.sentCount,
    required this.failedCount,
    required this.failedNumbers,
    this.wasCancelled = false,
  });

  factory SmsHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SmsHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messageText: json['messageText'] as String,
      recipientCount: json['recipientCount'] as int,
      sentCount: json['sentCount'] as int,
      failedCount: json['failedCount'] as int,
      failedNumbers: List<String>.from(json['failedNumbers'] as List),
      wasCancelled: json['wasCancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'messageText': messageText,
      'recipientCount': recipientCount,
      'sentCount': sentCount,
      'failedCount': failedCount,
      'failedNumbers': failedNumbers,
      'wasCancelled': wasCancelled,
    };
  }
}
