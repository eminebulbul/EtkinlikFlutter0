import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await _api.login(_emailCtrl.text.trim(), _passCtrl.text.trim());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result.token);
      await prefs.setInt('user_id', result.userId);
      await prefs.setString('user_name', result.name);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Hoş geldin 👋",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Etkinliklere katılmak için giriş yap.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-posta",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "E-posta zorunlu";
                      }
                      if (!value.contains('@')) {
                        return "Geçerli bir e-posta gir";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Şifre",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Şifre zorunlu";
                      }
                      if (value.length < 4) {
                        return "En az 4 karakter olmalı";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_error != null) ...[
                    Text(
                      _error!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Giriş yap"),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text("Hesabım yok, kayıt ol"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
