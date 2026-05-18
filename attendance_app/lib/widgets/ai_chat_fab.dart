import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';
import 'ai_chat_overlay.dart';

class AiChatFab extends ConsumerWidget {
  const AiChatFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(chatUnreadProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          onPressed: () {
            ref.read(chatProvider.notifier).markRead();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AiChatOverlay(),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
          label: const Text('AI 助手', style: TextStyle(color: Colors.white)),
          elevation: 6,
        ),
        if (hasUnread)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }
}
