import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/app_text_field.dart';
import '../../../core/theme/components/primary_button.dart';
import '../application/auth_service.dart';
import 'auth_error_message.dart';

/// Account creation screen (pushed from `/login`).
///
/// Flow: Supabase `signUp` then backend `POST /auth/register` (upsert).
/// On success with a session, the router's redirect takes
/// the user to the dashboard; without a session (email confirmation
/// enabled), a message invites them to check their inbox.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    // Holds back the router's redirect during the whole flow: the Supabase
    // session is issued as soon as signUp happens, before the backend responds.
    ref.read(registrationInProgressProvider.notifier).state = true;
    try {
      await ref
          .read(authServiceProvider)
          .registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Success with a session: explicit navigation (the flag will be released
      // in the finally block, the redirect cannot precede us).
      if (mounted) context.go(Routes.dashboard);
    } on EmailConfirmationRequiredException {
      _setInfo(l10n.authCheckEmail);
    } on Object catch (e) {
      _setError(authErrorMessage(l10n, e, authFailure: l10n.authSignUpFailed));
    } finally {
      ref.read(registrationInProgressProvider.notifier).state = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  void _setInfo(String message) {
    if (mounted) setState(() => _infoMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRegisterTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: l10n.authEmail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: l10n.authPassword,
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: l10n.authConfirmPassword,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    if (_infoMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _infoMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // Email confirmation required: send back to /login.
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: Text(l10n.authGoToLogin),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: l10n.authCreateAccount,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || !value.contains('@')) {
      return context.l10n.authEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return context.l10n.authPasswordMinLength;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return context.l10n.authPasswordsMismatch;
    }
    return null;
  }
}
