import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../inbox/smart_inbox_provider.dart';
import '../search/search_provider.dart';
import '../settings/settings_provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isRegistering ? 'Create your Vaultly account' : 'Welcome back',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to protect your memory vault and continue saving from anywhere.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    if (_isRegistering) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter your email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(auth),
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        auth.errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: auth.isBusy ? null : () => _submit(auth),
                      child: auth.isBusy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegistering ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: auth.isBusy
                          ? null
                          : () {
                              setState(() => _isRegistering = !_isRegistering);
                            },
                      child: Text(
                        _isRegistering
                            ? 'Already have an account? Sign in'
                            : 'New to Vaultly? Create account',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: auth.isBusy ? null : _continueOffline,
                      icon: const Icon(Icons.storage_rounded),
                      label: const Text('Continue without login'),
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

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    bool success;
    if (_isRegistering) {
      success = await auth.createAccount(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
    } else {
      success = await auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
    if (!success || !mounted) return;
    await context.read<SettingsProvider>().setUseLocalStorageWithoutLogin(false);
    context.read<CollectionProvider>().load();
    context.read<HomeProvider>().load();
    context.read<SearchProvider>().load();
    context.read<SmartInboxProvider>().load();
    final settings = context.read<SettingsProvider>();
    Navigator.pushNamedAndRemoveUntil(
      context,
      settings.hasCompletedOnboarding ? AppRoutes.shell : AppRoutes.onboarding,
      (route) => false,
    );
  }

  Future<void> _continueOffline() async {
    await context.read<SettingsProvider>().setUseLocalStorageWithoutLogin(true);
    if (!mounted) return;
    context.read<CollectionProvider>().load();
    context.read<HomeProvider>().load();
    context.read<SearchProvider>().load();
    context.read<SmartInboxProvider>().load();
    final settings = context.read<SettingsProvider>();
    Navigator.pushNamedAndRemoveUntil(
      context,
      settings.hasCompletedOnboarding ? AppRoutes.shell : AppRoutes.onboarding,
      (route) => false,
    );
  }
}
