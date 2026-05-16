class AttendanceRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String checkDate;
  final String checkTime;
  final String checkType;
  final String status;
  final bool isValid;
  final String source;
  final int? distanceMeters;
  final String? officeLocationName;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.checkDate,
    required this.checkTime,
    required this.checkType,
    required this.status,
    required this.isValid,
    required this.source,
    this.distanceMeters,
    this.officeLocationName,
  });

  bool get isCheckIn => checkType == 'CHECK_IN';
  bool get isLate => status == 'LATE';
  bool get isEarlyLeave => status == 'EARLY_LEAVE';

  String get timeDisplay => checkTime.length >= 16 ? checkTime.substring(11, 16) : checkTime;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        id: (json['id'] as num).toInt(),
        employeeId: (json['employeeId'] as num).toInt(),
        employeeName: json['employeeName'] as String,
        checkDate: json['checkDate'] as String,
        checkTime: json['checkTime'] as String,
        checkType: json['checkType'] as String,
        status: json['status'] as String,
        isValid: json['isValid'] as bool,
        source: json['source'] as String,
        distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
        officeLocationName: json['officeLocationName'] as String?,
      );
}
