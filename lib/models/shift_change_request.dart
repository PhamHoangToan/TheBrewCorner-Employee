class ShiftOption {
  ShiftOption({required this.id, required this.name, required this.startTime, required this.endTime});

  final String id;
  final String name;
  final String startTime;
  final String endTime;

  String get label => '$name ($startTime–$endTime)';

  factory ShiftOption.fromJson(Map<String, dynamic> json) => ShiftOption(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
      );
}

class ShiftChangeRequest {
  ShiftChangeRequest({
    required this.id,
    required this.type,
    required this.workDate,
    required this.reason,
    required this.status,
    required this.rejectReason,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String type; // REGISTER | SWAP
  final DateTime workDate;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED
  final String? rejectReason;
  final String shiftName;
  final String startTime;
  final String endTime;

  factory ShiftChangeRequest.fromJson(Map<String, dynamic> json) {
    final shift = json['shift'] as Map<String, dynamic>?;
    return ShiftChangeRequest(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'REGISTER',
      workDate: DateTime.parse(json['workDate'] as String),
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      rejectReason: json['rejectReason'] as String?,
      shiftName: shift?['name'] as String? ?? '',
      startTime: shift?['startTime'] as String? ?? '',
      endTime: shift?['endTime'] as String? ?? '',
    );
  }
}
