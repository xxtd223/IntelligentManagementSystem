class CalendarDay {
  final String date;
  final bool isWorkDay;
  final bool hasCheckIn;
  final bool hasCheckOut;
  final bool isMissing;
  final bool isLate;
  final bool isEarlyLeave;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInStatus;
  final String? checkOutStatus;
  final String? checkInSource;
  final String? checkOutSource;
  final String? note;

  bool get isManualCheckIn => checkInSource == 'MANUAL';
  bool get isManualCheckOut => checkOutSource == 'MANUAL';

  const CalendarDay({
    required this.date,
    required this.isWorkDay,
    required this.hasCheckIn,
    required this.hasCheckOut,
    required this.isMissing,
    required this.isLate,
    required this.isEarlyLeave,
    this.checkInTime,
    this.checkOutTime,
    this.checkInStatus,
    this.checkOutStatus,
    this.checkInSource,
    this.checkOutSource,
    this.note,
  });

  String get checkInTimeDisplay =>
      checkInTime != null && checkInTime!.length >= 16
          ? checkInTime!.substring(11, 16)
          : '--:--';

  String get checkOutTimeDisplay =>
      checkOutTime != null && checkOutTime!.length >= 16
          ? checkOutTime!.substring(11, 16)
          : '--:--';

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: json['date'] as String,
        isWorkDay: (json['isWorkDay'] ?? json['workDay']) as bool? ?? true,
        hasCheckIn: json['hasCheckIn'] as bool? ?? false,
        hasCheckOut: json['hasCheckOut'] as bool? ?? false,
        isMissing: (json['isMissing'] ?? json['missing']) as bool? ?? false,
        isLate: (json['isLate'] ?? json['late']) as bool? ?? false,
        isEarlyLeave: (json['isEarlyLeave'] ?? json['earlyLeave']) as bool? ?? false,
        checkInTime: json['checkInTime'] as String?,
        checkOutTime: json['checkOutTime'] as String?,
        checkInStatus: json['checkInStatus'] as String?,
        checkOutStatus: json['checkOutStatus'] as String?,
        checkInSource: json['checkInSource'] as String?,
        checkOutSource: json['checkOutSource'] as String?,
        note: json['note'] as String?,
      );
}
