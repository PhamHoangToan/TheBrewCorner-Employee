class ShiftAssignment {
  ShiftAssignment({
    required this.id,
    required this.workDate,
    required this.status,
    required this.note,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final DateTime workDate;
  final String status; // SCHEDULED | IN_PROGRESS | COMPLETED | ABSENT
  final String? note;
  final String shiftName;
  final String startTime;
  final String endTime;

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    final shift = json['shift'] as Map<String, dynamic>?;
    return ShiftAssignment(
      id: json['id'] as String,
      workDate: DateTime.parse(json['workDate'] as String),
      status: json['status'] as String? ?? 'SCHEDULED',
      note: json['note'] as String?,
      shiftName: shift?['name'] as String? ?? '',
      startTime: shift?['startTime'] as String? ?? '',
      endTime: shift?['endTime'] as String? ?? '',
    );
  }
}
