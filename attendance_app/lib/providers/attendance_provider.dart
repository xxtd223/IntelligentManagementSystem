import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/attendance_record.dart';
import '../models/calendar_day.dart';

class AttendanceState {
  final List<AttendanceRecord> todayRecords;
  final bool isLoading;
  final String? error;

  const AttendanceState({
    this.todayRecords = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasCheckIn => todayRecords.any((r) => r.isCheckIn && r.isValid);
  bool get hasCheckOut => todayRecords.any((r) => !r.isCheckIn && r.isValid);
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState());

  Future<void> loadToday() async {
    state = const AttendanceState(isLoading: true);
    try {
      final resp = await DioClient.get(ApiConstants.attendanceToday);
      final list = (resp['data'] as List)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AttendanceState(todayRecords: list);
    } catch (e) {
      state = AttendanceState(error: e.toString());
    }
  }

  Future<Map<String, dynamic>> checkIn(String type) async {
    Position? position;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {}

    final data = {
      'checkType': type,
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    };

    final resp = await DioClient.post(ApiConstants.checkIn, data: data);
    await loadToday();
    return resp['data'] as Map<String, dynamic>;
  }

  Future<List<CalendarDay>> getMonthlyCalendar(int year, int month,
      {int? employeeId}) async {
    final resp = await DioClient.get(ApiConstants.attendanceCalendar, queryParams: {
      'year': year,
      'month': month,
      if (employeeId != null) 'employeeId': employeeId,
    });
    return (resp['data'] as List)
        .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month,
      {int? employeeId}) async {
    final resp = await DioClient.get(ApiConstants.attendanceSummary, queryParams: {
      'year': year,
      'month': month,
      if (employeeId != null) 'employeeId': employeeId,
    });
    return resp['data'] as Map<String, dynamic>;
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});
