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
  static const String attendanceManual = '/attendance/admin/manual';

  static const String workCalendar = '/work-calendar';
  static const String workCalendarBatch = '/work-calendar/batch';
  static const String workCalendarLocationBatch = '/work-calendar/location-batch';

  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  static const String aiChat = '/ai/chat';
  static const String aiChatSession = '/ai/chat/session';

  // 高德地图 Web 端 API Key，请在 https://lbs.amap.com 申请
  static const String amapWebKey = '4f491568e24aada8a0235e2bf7e31fb7'; // ← 把这里替换成你的 Key
}
