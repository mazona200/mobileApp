import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

PreferredSizeWidget buildSharedAppBar({required Widget title, required BuildContext context}) {
  return AppBar(
    title: title,
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Notifications"),
              content: const Text("You have no new notifications."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
              ],
            ),
          );
        },
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'settings') {
            // TODO: Implement settings navigation
          } else if (value == 'logout') {
            FirebaseAuth.instance.signOut();
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'settings', child: Text('Settings')),
          PopupMenuItem(value: 'logout', child: Text('Logout')),
        ],
      ),
      const SizedBox(width: 8),
    ],
  );
}
