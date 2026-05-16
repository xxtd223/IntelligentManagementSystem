import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import 'ai_chat_overlay.dart';

class AiChatFab extends ConsumerWidget {
  const AiChatFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
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
    );
  }
}
