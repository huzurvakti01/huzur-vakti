class SecureNote {
  final String id;
  final String text;
  final DateTime createdAt;

  const SecureNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  factory SecureNote.fromJson(Map<String, dynamic> json) {
    return SecureNote(
      id: json['id'].toString(),
      text: json['text'].toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
