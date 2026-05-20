class ApiConstants {
  static const String baseUrl = 'http://10.10.0.197:8080/api/v1';

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
  static const String workCalendarLocationGet = '/work-calendar/location';

  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  static const String aiChat = '/ai/chat';
  static const String aiChatSession = '/ai/chat/session';

  // 高德地图 Web 端 API Key，请在 https://lbs.amap.com 申请
  // 高德地图 Web 端 JS API Key — 在 https://console.amap.com 创建「Web端(JS API)」应用后获取
  static const String amapWebKey = '';
  // 高德地图 JS 安全密钥 — 同一应用的「安全密钥」，2021年后创建的应用必填；留空则地图瓦片无法加载
  static const String amapSecurityCode = '';
}
