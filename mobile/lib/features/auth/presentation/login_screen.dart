import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/supabase_config.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/app_text_field.dart';
import '../../../core/theme/components/primary_button.dart';
import '../application/auth_service.dart';
import 'auth_error_message.dart';

/// Sign-in screen: Sign in with Apple (iOS) or email + password.
///
/// Navigation after success is handled by the router's redirect
/// (the session appears in `authSessionProvider`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  /// Sign in with Apple: iOS only. No Android web flow for
  /// now (decision logged in the journal, phase 3.1).
  static bool get _showAppleButton =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on Object catch (e) {
      _setError(authErrorMessage(l10n, e, authFailure: l10n.authLoginFailed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithApple();
    } on AuthCancelledException {
      // Apple sheet closed by the user: no message.
    } on Object catch (e) {
      _setError(authErrorMessage(l10n, e, authFailure: l10n.authLoginFailed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Developer shortcut (debug only).
  ///
  /// With `DEV_LOGIN_EMAIL`/`DEV_LOGIN_PASSWORD` and Supabase configured:
  /// fills the form and submits. Otherwise, bypass without a session (in the
  /// spirit of the iOS `devSignIn()` — dev UI without a backend).
  Future<void> _devLogin() async {
    const devEmail = String.fromEnvironment('DEV_LOGIN_EMAIL');
    const devPassword = String.fromEnvironment('DEV_LOGIN_PASSWORD');
    if (SupabaseConfig.isConfigured &&
        devEmail.isNotEmpty &&
        devPassword.isNotEmpty) {
      _emailController.text = devEmail;
      _passwordController.text = devPassword;
      await _submit();
    } else {
      ref.read(devAuthBypassProvider.notifier).state = true;
    }
  }

  /// One-tap sign-in with the shared demo account (showcase mode).
  Future<void> _demoSignIn(DemoLoginConfig demo) async {
    _emailController.text = demo.email;
    _passwordController.text = demo.password;
    await _submit();
  }

  void _setError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final demo = ref.watch(demoLoginConfigProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authLoginSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (_showAppleButton) ...[
                  SignInWithAppleButton(
                    onPressed: _isLoading ? null : _signInWithApple,
                    text: l10n.authSignInWithApple,
                    style: SignInWithAppleButtonStyle.black,
                    height: 50,
                    borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.authOr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                AppCard(
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
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: _validatePassword,
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
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: l10n.authSignIn,
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (demo != null) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.authDemoBannerTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.authDemoBannerBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: l10n.authDemoSignIn,
                          isLoading: _isLoading,
                          onPressed: () => _demoSignIn(demo),
                        ),
                      ],
                    ),
                  ),
                ],
                if (demo == null)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.push(Routes.register),
                    child: Text(l10n.authNoAccount),
                  ),
                if (kDebugMode)
                  TextButton(
                    onPressed: _isLoading ? null : _devLogin,
                    child: Text(
                      'Dev Login',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.appColors.warning,
                      ),
                    ),
                  ),
              ],
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
    // Sign-in: "non-empty" is enough — the ≥ 8 character rule only
    // applies to registration (iOS parity, which doesn't validate at login).
    if (value == null || value.isEmpty) {
      return context.l10n.authPasswordRequired;
    }
    return null;
  }
}
