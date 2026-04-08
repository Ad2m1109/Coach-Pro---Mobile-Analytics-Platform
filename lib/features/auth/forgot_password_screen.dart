import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isSendingCode = false;
  bool _isResettingPassword = false;
  bool _hasSentCode = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isSendingCode = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final detail = await authService.requestPasswordResetCode(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _hasSentCode = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_emailFormKey.currentState!.validate()) return;
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isResettingPassword = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final detail = await authService.resetPasswordWithCode(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _newPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail)),
      );
      context.goNamed(AppRouteConstants.loginRouteName);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _hasSentCode
                    ? 'Enter the 6-digit code from your email and choose a new password.'
                    : 'Enter your email and we will send you a 6-digit reset code.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.l),
              Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    CustomButton(
                      text: _hasSentCode ? 'Resend Code' : 'Send Code',
                      onPressed: _sendCode,
                      isLoading: _isSendingCode,
                    ),
                  ],
                ),
              ),
              if (_hasSentCode) ...[
                const SizedBox(height: AppSpacing.xl),
                Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Reset Code',
                          hintText: '123456',
                          prefixIcon: Icon(Icons.password_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.length != 6) {
                            return 'Enter the 6-digit code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.m),
                      CustomTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
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
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomButton(
                        text: 'Reset Password',
                        onPressed: _resetPassword,
                        isLoading: _isResettingPassword,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              TextButton(
                onPressed: () => context.goNamed(AppRouteConstants.loginRouteName),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
