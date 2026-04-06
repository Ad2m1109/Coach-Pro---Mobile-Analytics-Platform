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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool _isLoading = false;
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
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.register(
          _emailController.text,
          _passwordController.text,
          _fullNameController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.registrationSuccessful)),
        );
        context.goNamed(
          AppRouteConstants.strategieRouteName,
        ); // Navigate to main app after successful registration and login
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLocalizations.registrationFailed(e.message)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalizations.anUnexpectedErrorOccurredWithMessage(e.toString()),
            ),
          ),
        );
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
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.loginWithGoogle();
      if (mounted && authService.isAuthenticated) {
        context.goNamed(AppRouteConstants.strategieRouteName);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('cancelled')
                  ? 'Sign in cancelled'
                  : _formatUnexpectedError(e),
            ),
          ),
        );
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
      appBar: AppBar(title: Text(appLocalizations.register)),
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
                    if (value == null || value.isEmpty) {
                      return appLocalizations.pleaseEnterYourEmail;
                    }
                    // Basic email validation
                    if (!RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    ).hasMatch(value)) {
                      return appLocalizations.pleaseEnterAValidEmailAddress;
                    }
                    return null;
                  },
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
                    if (value == null || value.isEmpty) {
                      return appLocalizations.pleaseEnterYourPassword;
                    }
                    if (value.length < 6) {
                      return appLocalizations.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  controller: _fullNameController,
                  label: appLocalizations.fullNameOptional,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  text: appLocalizations.register,
                  onPressed: _register,
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
                    label: Text(appLocalizations.signUpWithGoogle),
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
                    context.go('/login');
                  },
                  child: Text(appLocalizations.alreadyHaveAnAccountLoginHere),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
