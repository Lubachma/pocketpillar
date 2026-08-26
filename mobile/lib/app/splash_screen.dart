import 'package:flutter/material.dart';

/// Neutral screen shown while rereading the persisted session
/// (`authSessionProvider.isLoading`): avoids the dashboard flashing for
/// a signed-out user — and `/login` flashing for a signed-in one. The
/// router redirects as soon as the session is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
