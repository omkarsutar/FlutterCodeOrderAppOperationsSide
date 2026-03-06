import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmLabel,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

/* Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false; // default to false if dismissed
}

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to Logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false; // default to false if dismissed
} */

Future<void> showLoadingDialog({
  required BuildContext context,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      ),
    ),
  );
}
