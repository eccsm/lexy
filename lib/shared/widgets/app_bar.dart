import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';


class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showProfileButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showProfileButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : null,
      actions: [
        ...?actions,
        if (showProfileButton)
          IconButton(
            icon: authState.when(
              data: (user) {
                if (user?.photoURL != null) {
                  return CircleAvatar(
                    backgroundImage: NetworkImage(user!.photoURL!),
                    radius: 14,
                  );
                }
                return const Icon(Icons.account_circle);
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Icon(Icons.account_circle),
            ),
            onPressed: () => context.push('/profile'),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}