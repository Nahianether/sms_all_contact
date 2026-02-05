class SmsTemplate {
  final String id;
  final String name;
  final String messageText;
  final DateTime createdAt;

  const SmsTemplate({
    required this.id,
    required this.name,
    required this.messageText,
    required this.createdAt,
  });

  factory SmsTemplate.fromJson(Map<String, dynamic> json) {
    return SmsTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      messageText: json['messageText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'messageText': messageText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SmsTemplate copyWith({String? name, String? messageText}) {
    return SmsTemplate(
      id: id,
      name: name ?? this.name,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt,
    );
  }
}
