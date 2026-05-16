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
  final String? note;

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
        isWorkDay: json['isWorkDay'] as bool? ?? true,
        hasCheckIn: json['hasCheckIn'] as bool? ?? false,
        hasCheckOut: json['hasCheckOut'] as bool? ?? false,
        isMissing: json['isMissing'] as bool? ?? false,
        isLate: json['isLate'] as bool? ?? false,
        isEarlyLeave: json['isEarlyLeave'] as bool? ?? false,
        checkInTime: json['checkInTime'] as String?,
        checkOutTime: json['checkOutTime'] as String?,
        checkInStatus: json['checkInStatus'] as String?,
        checkOutStatus: json['checkOutStatus'] as String?,
        note: json['note'] as String?,
      );
}
