class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reason,
    required this.status,
    required this.rejectReason,
    required this.createdAt,
  });

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // ANNUAL | SICK | UNPAID
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED
  final String? rejectReason;
  final DateTime createdAt;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id: json['id'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        type: json['type'] as String? ?? 'ANNUAL',
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        rejectReason: json['rejectReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
