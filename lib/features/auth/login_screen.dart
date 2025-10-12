import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/routes/app_router.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final appLocalizations = AppLocalizations.of(context)!;
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
        setState(() {
          _passwordController.clear();
          if (e.message.toLowerCase().contains('account does not exist')) {
            _emailApiError = e.message;
          } else if (e.message.toLowerCase().contains('incorrect password')) {
            _passwordApiError = e.message;
          } else {
            _passwordApiError = e.message; // Show other errors under password field
          }
        });
      } catch (e) {
        setState(() {
          _passwordController.clear();
          _passwordApiError = appLocalizations.anUnexpectedErrorOccurred;
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.login),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.email,
                    border: const OutlineInputBorder(),
                    errorText: _emailApiError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_emailApiError != null) return null;
                    if (value == null || value.isEmpty) {
                      return appLocalizations.pleaseEnterYourEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.password,
                    border: const OutlineInputBorder(),
                    errorText: _passwordApiError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (_passwordApiError != null) return null;
                    if (value == null || value.isEmpty) {
                      return appLocalizations.pleaseEnterYourPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: Text(appLocalizations.login),
                      ),
                const SizedBox(height: 16.0),
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
