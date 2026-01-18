import 'package:flutter/material.dart';

/// Show a snackbar with selectable text content
void showSelectableSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SelectableText(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isError ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Show an error snackbar with selectable text
void showErrorSnackBar(BuildContext context, String error) {
  showSelectableSnackBar(context, error, isError: true);
}

/// Show a success snackbar with selectable text
void showSuccessSnackBar(BuildContext context, String message) {
  showSelectableSnackBar(context, message, isError: false);
}
