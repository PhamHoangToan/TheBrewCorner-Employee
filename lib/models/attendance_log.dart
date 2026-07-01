class AttendanceLog {
  AttendanceLog({
    required this.id,
    required this.workDate,
    required this.checkIn,
    required this.checkOut,
    required this.note,
  });

  final String id;
  final DateTime workDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? note;

  factory AttendanceLog.fromJson(Map<String, dynamic> json) => AttendanceLog(
        id: json['id'] as String,
        workDate: DateTime.parse(json['workDate'] as String),
        checkIn: json['checkIn'] != null ? DateTime.parse(json['checkIn'] as String) : null,
        checkOut: json['checkOut'] != null ? DateTime.parse(json['checkOut'] as String) : null,
        note: json['note'] as String?,
      );
}

class AttendanceCorrectionRequest {
  AttendanceCorrectionRequest({
    required this.id,
    required this.workDate,
    required this.checkIn,
    required this.checkOut,
    required this.reason,
    required this.status,
    required this.rejectReason,
  });

  final String id;
  final DateTime workDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED
  final String? rejectReason;

  factory AttendanceCorrectionRequest.fromJson(Map<String, dynamic> json) => AttendanceCorrectionRequest(
        id: json['id'] as String,
        workDate: DateTime.parse(json['workDate'] as String),
        checkIn: json['checkIn'] != null ? DateTime.parse(json['checkIn'] as String) : null,
        checkOut: json['checkOut'] != null ? DateTime.parse(json['checkOut'] as String) : null,
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        rejectReason: json['rejectReason'] as String?,
      );
}
