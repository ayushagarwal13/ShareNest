import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'sign_in_screen.dart' show GoogleGLogo;

// ShareNest design tokens (same values as the main app theme).
const _teal = Color(0xFF0F766E);
const _darkTeal = Color(0xFF0B4F4A);
const _mint = Color(0xFFDDF5EC);
const _canvas = Color(0xFFFAFAF7);
const _ink = Color(0xFF14231F);
const _muted = Color(0xFF5B6B66);
const _line = Color(0xFFE3EAE6);
const _leaf = Color(0xFF8EB6A1);
const _error = Color(0xFFB3382C);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;

  bool get _busy => _loading || _googleLoading;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (_) {
      _showMessage('Unable to create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createAccountWithGoogle() async {
    if (_busy) return;

    setState(() => _googleLoading = true);

    try {
      await AuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (_) {
      _showMessage('Google sign-up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-up method is not enabled yet.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return e.message ?? 'Account creation failed. Please try again.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String hint, IconData icon) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(icon, color: _muted, size: 23),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      errorStyle: const TextStyle(
        color: _error,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      border: border(_line),
      enabledBorder: border(_line),
      focusedBorder: border(_teal, 2),
      errorBorder: border(_error),
      focusedErrorBorder: border(_error, 2),
    );
  }

  Widget _brandHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/sharenest_house_sprout_logo.png',
          width: 76,
          height: 76,
          fit: BoxFit.contain,
          semanticLabel: 'ShareNest logo',
          errorBuilder: (_, _, _) => const _LogoFallback(size: 76),
        ),
        const SizedBox(height: 6),
        const Text(
          'Join ShareNest',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: _darkTeal,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make shared expenses simple.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: _muted),
        ),
      ],
    );
  }

  /// Full-width illustration, a little shorter than on sign-in so the longer
  /// form stays close to the top.
  Widget _friendsIllustration() {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Image.asset(
        'assets/images/sharenest_friends_illustration.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        semanticLabel: 'Four friends sharing expenses',
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _googleButton() {
    return OutlinedButton(
      onPressed: _busy ? null : _createAccountWithGoogle,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        side: const BorderSide(color: _line),
        shape: const StadiumBorder(),
      ),
      child: _googleLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoogleGLogo(size: 24),
                SizedBox(width: 12),
                Text(
                  'Sign up with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }

  Widget _createAccountButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: _busy ? 0 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: _busy ? null : _createAccount,
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canGoBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 0, 0),
                            child: IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: _ink,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 28),
                      _brandHeader(),
                      const SizedBox(height: 8),
                      _friendsIllustration(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _googleButton(),
                            const SizedBox(height: 20),
                            const _OrDivider(label: 'OR SIGN UP WITH EMAIL'),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: _decoration(
                                'Full name',
                                Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your full name.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: _decoration(
                                'Email address',
                                Icons.mail_outline_rounded,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Enter your email address.';
                                }

                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)) {
                                  return 'Enter a valid email address.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _createAccount(),
                              decoration:
                                  _decoration(
                                    'Password',
                                    Icons.lock_outline_rounded,
                                  ).copyWith(
                                    helperText: '8+ characters, uppercase, lowercase, number & symbol',
                                    helperStyle: const TextStyle(
                                      color: _muted,
                                      fontSize: 12.5,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _muted,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                              validator: (value) {
                                final password = value ?? '';

                                if (password.length < 8) {
                                  return 'Use at least 8 characters.';
                                }
                                if (!RegExp(r'[A-Z]').hasMatch(password)) {
                                  return 'Add at least one uppercase letter (A–Z).';
                                }
                                if (!RegExp(r'[a-z]').hasMatch(password)) {
                                  return 'Add at least one lowercase letter (a–z).';
                                }
                                if (!RegExp(r'[0-9]').hasMatch(password)) {
                                  return 'Add at least one number (0–9).';
                                }
                                if (!RegExp(r'[^A-Za-z0-9]')
                                    .hasMatch(password)) {
                                  return 'Add at least one special character (e.g. @ or #).';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _createAccountButton(),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(color: _muted, fontSize: 15),
                                ),
                                TextButton(
                                  onPressed: _busy ? null : widget.onSignIn,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      color: _teal,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const _LeafDivider(),
                            const SizedBox(height: 14),
                            const _LegalText(
                              prefix:
                                  'By creating an account, you agree to our ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- SMALL WIDGETS ----------

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: _line)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const Expanded(child: Divider(color: _line)),
    ],
  );
}

class _LeafDivider extends StatelessWidget {
  const _LeafDivider();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _line)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.eco_rounded, color: _leaf, size: 24),
      ),
      Expanded(child: Divider(color: _line)),
    ],
  );
}

class _LegalText extends StatelessWidget {
  const _LegalText({required this.prefix});

  final String prefix;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(color: _muted, fontSize: 12.5, height: 1.5);
    const link = TextStyle(
      color: _teal,
      fontSize: 12.5,
      height: 1.5,
      fontWeight: FontWeight.w500,
    );

    // TODO: make the two links tappable once the policy URLs exist.
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: prefix),
          const TextSpan(text: 'Terms of Service', style: link),
          const TextSpan(text: ' and '),
          const TextSpan(text: 'Privacy Policy', style: link),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Shown only if the logo asset is missing, so the screen never breaks.
class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(Icons.home_rounded, size: size * 0.55, color: _darkTeal),
  );
}
