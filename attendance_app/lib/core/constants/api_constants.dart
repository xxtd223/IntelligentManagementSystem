class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String employees = '/employees';
  static const String departments = '/departments';
  static const String officeLocations = '/office-locations';

  static const String checkIn = '/attendance/check-in';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceRecords = '/attendance/records';
  static const String attendanceCalendar = '/attendance/calendar';
  static const String attendanceSummary = '/attendance/summary';

  static const String workCalendar = '/work-calendar';
  static const String workCalendarBatch = '/work-calendar/batch';

  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  static const String aiChat = '/ai/chat';
  static const String aiChatSession = '/ai/chat/session';
}
