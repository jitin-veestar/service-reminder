class ServiceNote {
  final String id;
  final String? noteData;
  final DateTime noteTime;
  final String message;
  final String status;

  const ServiceNote({
    required this.id,
    this.noteData,
    required this.noteTime,
    required this.message,
    this.status = 'general',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'note_data': noteData,
        'note_time': noteTime.toIso8601String(),
        'message': message,
        'status': status,
      };

  factory ServiceNote.fromJson(Map<String, dynamic> json) => ServiceNote(
        id: json['id'] as String,
        noteData: json['note_data'] as String?,
        noteTime: DateTime.parse(json['note_time'] as String),
        message: json['message'] as String,
        status: (json['status'] as String?) ?? 'general',
      );
}
