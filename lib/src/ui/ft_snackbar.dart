import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_haptics.dart';

void showFtErrorSnack(
  BuildContext context,
  Object error, {
  String? prefix,
}) {
  FtHaptics.error();
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final text = prefix == null ? '$error' : '$prefix: $error';
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: FtColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
}

void showFtInfoSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}
