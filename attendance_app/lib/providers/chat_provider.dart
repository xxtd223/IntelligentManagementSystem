import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/storage/local_storage.dart';
import '../models/chat_message.dart';
import 'attendance_provider.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this._ref) : super([]);

  final Ref _ref;
  String? _sessionKey;
  bool _hasUnread = false;

  bool get hasUnreadReminder => _hasUnread;

  void markRead() {
    if (_hasUnread) {
      _hasUnread = false;
    }
  }

  void addReminderMessage(String text) {
    final msg = ChatMessage(
      role: MessageRole.assistant,
      content: text,
      timestamp: DateTime.now(),
      isReminder: true,
    );
    state = [...state, msg];
    _hasUnread = true;
  }

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    final loadingMsg = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, userMsg, loadingMsg];

    try {
      _sessionKey ??= await LocalStorage.getAiSessionKey();

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {}

      final reqData = {
        'message': text,
        if (_sessionKey != null) 'sessionKey': _sessionKey,
        if (position != null) 'latitude': position.latitude,
        if (position != null) 'longitude': position.longitude,
      };

      final resp = await DioClient.post(ApiConstants.aiChat, data: reqData);
      final data = resp['data'] as Map<String, dynamic>;
      final reply = data['reply'] as String;
      final actionTaken = data['actionTaken'] as String?;
      final newSessionKey = data['sessionKey'] as String?;

      if (newSessionKey != null) {
        _sessionKey = newSessionKey;
        await LocalStorage.saveAiSessionKey(newSessionKey);
      }

      if (actionTaken == 'CHECK_IN' || actionTaken == 'CHECK_OUT') {
        _ref.read(attendanceProvider.notifier).loadToday();
      }

      final assistantMsg = ChatMessage(
        role: MessageRole.assistant,
        content: reply,
        timestamp: DateTime.now(),
      );
      state = [...state.sublist(0, state.length - 1), assistantMsg];
    } catch (e) {
      final errorMsg = ChatMessage(
        role: MessageRole.assistant,
        content: '抱歉，服务暂时不可用，请稍后重试。',
        timestamp: DateTime.now(),
      );
      state = [...state.sublist(0, state.length - 1), errorMsg];
    }
  }

  Future<void> clearHistory() async {
    await DioClient.delete(ApiConstants.aiChatSession);
    _sessionKey = null;
    await LocalStorage.saveAiSessionKey('');
    state = [];
    _hasUnread = false;
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

final chatUnreadProvider = Provider<bool>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  ref.watch(chatProvider);
  return notifier.hasUnreadReminder;
});
