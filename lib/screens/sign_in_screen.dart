import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;

  bool get _busy => _loading || _googleLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (_) {
      _showMessage('Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;

    setState(() => _googleLoading = true);

    try {
      await AuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (_) {
      _showMessage('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Enter your email address first.');
      return;
    }

    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      _showMessage(
        'If an account exists for that email, a reset email will be sent.',
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (_) {
      _showMessage('Unable to send the reset email. Please try again.');
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'google-sign-in-no-id-token':
        return 'Google sign-in could not be completed. Please try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
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
          width: 84,
          height: 84,
          fit: BoxFit.contain,
          semanticLabel: 'ShareNest logo',
          errorBuilder: (_, _, _) => const _LogoFallback(size: 84),
        ),
        const SizedBox(height: 6),
        const Text(
          'ShareNest',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: _darkTeal,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Split expenses. Stay connected.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: _muted),
        ),
      ],
    );
  }

  /// Full-width illustration (leaves run to the screen edges).
  Widget _friendsIllustration() {
    return SizedBox(
      width: double.infinity,
      height: 200,
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
      onPressed: _busy ? null : _signInWithGoogle,
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
                  'Continue with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }

  Widget _signInButton() {
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
        onPressed: _busy ? null : _signInWithEmail,
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
                    'Sign in',
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
                      const SizedBox(height: 10),
                      _friendsIllustration(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _googleButton(),
                            const SizedBox(height: 20),
                            const _OrDivider(label: 'OR CONTINUE WITH EMAIL'),
                            const SizedBox(height: 18),
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
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _signInWithEmail(),
                              decoration:
                                  _decoration(
                                    'Password',
                                    Icons.lock_outline_rounded,
                                  ).copyWith(
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
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password.';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetPassword,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 44),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: _teal,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            _signInButton(),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'New to ShareNest?',
                                  style: TextStyle(color: _muted, fontSize: 15),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : widget.onCreateAccount,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Create account',
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
                              prefix: 'By continuing, you agree to our ',
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

// ---------- SHARED SMALL WIDGETS ----------

/// The official multicolour Google "G", drawn from the standard 48x48 vector
/// outline so no image asset is needed. For store submission you may prefer
/// Google's own downloadable asset: https://developers.google.com/identity/branding-guidelines
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _GoogleGPainter()),
  );
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);

    Paint fill(int argb) => Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = Color(argb);

    // Red (top).
    final red = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();

    // Blue (right, with the crossbar).
    final blue = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();

    // Yellow (left).
    final yellow = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
      ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();

    // Green (bottom).
    final green = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();

    canvas.drawPath(red, fill(0xFFEA4335));
    canvas.drawPath(blue, fill(0xFF4285F4));
    canvas.drawPath(yellow, fill(0xFFFBBC05));
    canvas.drawPath(green, fill(0xFF34A853));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
