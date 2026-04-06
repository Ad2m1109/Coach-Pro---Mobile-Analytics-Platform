import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/routes/app_router.dart';

import 'package:frontend/widgets/custom_text_field.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailApiError;
  String? _passwordApiError;
  bool _isPasswordVisible = false;

  String _formatUnexpectedError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Clear previous API errors
    setState(() {
      _emailApiError = null;
      _passwordApiError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.login(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          context.goNamed(AppRouteConstants.strategieRouteName);
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _passwordController.clear();
          if (e.message.toLowerCase().contains('account does not exist')) {
            _emailApiError = e.message;
          } else if (e.message.toLowerCase().contains('incorrect password')) {
            _passwordApiError = e.message;
          } else {
            _passwordApiError =
                e.message; // Show other errors under password field
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _passwordController.clear();
          _passwordApiError = _formatUnexpectedError(e);
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _emailApiError = null;
      _passwordApiError = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.loginWithGoogle();
      if (mounted && authService.isAuthenticated) {
        context.goNamed(AppRouteConstants.strategieRouteName);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _passwordApiError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!e.toString().contains('cancelled')) {
            _passwordApiError = _formatUnexpectedError(e);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.login)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                  controller: _emailController,
                  label: appLocalizations.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_emailApiError != null) return null;
                    if (value == null || value.isEmpty) {
                      return appLocalizations.pleaseEnterYourEmail;
                    }
                    return null;
                  },
                ),
                if (_emailApiError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _emailApiError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  controller: _passwordController,
                  label: appLocalizations.password,
                  prefixIcon: Icons.lock_outline,
                  isPassword: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (_passwordApiError != null) return null;
                    if (value == null || value.isEmpty) {
                      return appLocalizations.pleaseEnterYourPassword;
                    }
                    return null;
                  },
                ),
                if (_passwordApiError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _passwordApiError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  text: appLocalizations.login,
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
                if (authService.isGoogleSignInAvailable) ...[
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                        child: Text(
                          appLocalizations.or,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: const Icon(Icons.login),
                    label: Text(appLocalizations.signInWithGoogle),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.s),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.m),
                TextButton(
                  onPressed: () {
                    context.go('/register');
                  },
                  child: Text(appLocalizations.dontHaveAnAccountRegisterHere),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
