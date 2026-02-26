import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/utils/dialogs.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const CustomAppBar({
    required this.title,
    this.showBack = true,
    this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : null, // ✅ Let Flutter show drawer icon if showBack is false
      title: Text(title),
      automaticallyImplyLeading:
          !showBack, // ✅ Enable drawer icon when back is off
      actions: [
        ...?actions, // ✅ allows additional actions from the page
        if (hasSession)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: 'Logout',
                content: 'Are you sure you want to Logout?',
                confirmLabel: 'Logout',
              );
              if (confirmed) {
                await ref.read(authServiceProvider).signOut();
              }
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
