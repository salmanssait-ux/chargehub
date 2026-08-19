import 'package:flutter/material.dart';

import '../../../stations/presentation/pages/stations_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const StationsPage(),
      ),
    );
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const StationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ─────────────────────────────────────
                  // LOGO
                  // ─────────────────────────────────────
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.ev_station_rounded,
                        size: 42,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─────────────────────────────────────
                  // TITLE
                  // ─────────────────────────────────────
                  Text(
                    'Welcome to ChargeHub',
                    textAlign: TextAlign.center,
                    style:
                    theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Find nearby EV charging stations quickly.',
                    textAlign: TextAlign.center,
                    style:
                    theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ─────────────────────────────────────
                  // EMAIL
                  // ─────────────────────────────────────
                  TextField(
                    controller: _emailController,
                    keyboardType:
                    TextInputType.emailAddress,
                    textInputAction:
                    TextInputAction.next,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color:
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─────────────────────────────────────
                  // PASSWORD
                  // ─────────────────────────────────────
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction:
                    TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color:
                        colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                            !_obscurePassword;
                          });
                        },
                        color:
                        colorScheme.onSurfaceVariant,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─────────────────────────────────────
                  // FORGOT PASSWORD
                  // ─────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot password?',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ─────────────────────────────────────
                  // LOGIN
                  // ─────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _login,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ─────────────────────────────────────
                  // DIVIDER
                  // ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color:
                          colorScheme.outlineVariant,
                        ),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Text(
                          'OR',
                          style:
                          theme.textTheme.labelSmall
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color:
                          colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ─────────────────────────────────────
                  // GUEST
                  // ─────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _continueAsGuest,
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─────────────────────────────────────
                  // SIGN UP
                  // ─────────────────────────────────────
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style:
                        theme.textTheme.bodyMedium
                            ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Sign up',
                        ),
                      ),
                    ],
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