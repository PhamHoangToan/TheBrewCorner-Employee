/// Prisma `Decimal` fields are serialized as strings (e.g. `"35000.00"`),
/// never as JSON numbers — always parse through this helper.
num _decimal(dynamic v) => num.tryParse(v?.toString() ?? '0') ?? 0;

class Payroll {
  Payroll({
    required this.id,
    required this.periodYear,
    required this.periodMonth,
    required this.employmentType,
    required this.scheduledDays,
    required this.workedDays,
    required this.paidLeaveDays,
    required this.absentDays,
    required this.totalHours,
    required this.otHours,
    required this.otAmount,
    required this.penaltyAmount,
    required this.totalAmount,
    required this.status,
  });

  final String id;
  final int periodYear;
  final int periodMonth;
  final String employmentType;
  final int scheduledDays;
  final int workedDays;
  final int paidLeaveDays;
  final int absentDays;
  final num totalHours;
  final num otHours;
  final num otAmount;
  final num penaltyAmount;
  final num totalAmount;
  final String status; // DRAFT | APPROVED | PAID

  factory Payroll.fromJson(Map<String, dynamic> json) => Payroll(
        id: json['id'] as String,
        periodYear: json['periodYear'] as int,
        periodMonth: json['periodMonth'] as int,
        employmentType: json['employmentType'] as String? ?? 'FULL_TIME',
        scheduledDays: json['scheduledDays'] as int? ?? 0,
        workedDays: json['workedDays'] as int? ?? 0,
        paidLeaveDays: json['paidLeaveDays'] as int? ?? 0,
        absentDays: json['absentDays'] as int? ?? 0,
        totalHours: _decimal(json['totalHours']),
        otHours: _decimal(json['otHours']),
        otAmount: _decimal(json['otAmount']),
        penaltyAmount: _decimal(json['penaltyAmount']),
        totalAmount: _decimal(json['totalAmount']),
        status: json['status'] as String? ?? 'DRAFT',
      );
}
