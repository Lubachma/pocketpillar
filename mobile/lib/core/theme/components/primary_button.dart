import 'package:flutter/material.dart';

/// Full-width primary button with a loading state
/// (equivalent of the iOS LoadingButton).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(label);
    return SizedBox(
      width: double.infinity,
      child: icon != null
          ? FilledButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon),
              label: child,
            )
          : FilledButton(onPressed: isLoading ? null : onPressed, child: child),
    );
  }
}
