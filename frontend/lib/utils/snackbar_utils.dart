import 'package:flutter/material.dart';

/// Strip "Exception: " prefix and clean up error messages for display
String cleanErrorMessage(Object error) {
  var msg = error.toString();
  // Remove "Exception: " prefix that Dart adds
  if (msg.startsWith('Exception: ')) {
    msg = msg.substring('Exception: '.length);
  }
  return msg;
}

/// Show a snackbar with proper styling
void showSelectableSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
      duration: Duration(seconds: isError ? 5 : 3),
    ),
  );
}

/// Show an error snackbar
void showErrorSnackBar(BuildContext context, String error) {
  showSelectableSnackBar(context, error, isError: true);
}

/// Show a success snackbar
void showSuccessSnackBar(BuildContext context, String message) {
  showSelectableSnackBar(context, message, isError: false);
}
