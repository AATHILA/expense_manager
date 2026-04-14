import 'package:flutter/material.dart';

/// Custom page route with loading transition
class LoadingPageRoute<T> extends PageRouteBuilder<T> {
  LoadingPageRoute({
    required Widget page,
    super.transitionDuration = const Duration(milliseconds: 300),
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    reverseTransitionDuration: transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade transition
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// Helper function to navigate with loading transition
Future<T?> navigateWithLoading<T>(
    BuildContext context,
    Widget page, {
      Duration? transitionDuration,
    }) {
  return Navigator.push<T>(
    context,
    LoadingPageRoute<T>(
      page: page,
      transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    ),
  );
}

/// Helper function to navigate with loading transition and show loading overlay
Future<T?> navigateWithLoadingOverlay<T>(
    BuildContext context,
    Widget page, {
      Duration? loadingDuration,
      Duration? transitionDuration,
    }) async {
  // Show loading overlay
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
    ),
  );

  // Wait for a short duration to show the loader
  await Future.delayed(loadingDuration ?? const Duration(milliseconds: 200));

  // Close the loading dialog
  if (context.mounted) {
    Navigator.pop(context);
  }

  // Navigate to the page with transition
  if (context.mounted) {
    return Navigator.push<T>(
      context,
      LoadingPageRoute<T>(
        page: page,
        transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  return null;
}

