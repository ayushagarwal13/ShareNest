import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'email_verification_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.home});

  final Widget home;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSignUp = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAF7),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          final hasEmailPasswordProvider = user.providerData.any(
            (provider) => provider.providerId == 'password',
          );

          if (hasEmailPasswordProvider && !user.emailVerified) {
            return EmailVerificationScreen(user: user);
          }

          return widget.home;
        }

        if (_showSignUp) {
          return SignUpScreen(
            onSignIn: () => setState(() => _showSignUp = false),
          );
        }

        return SignInScreen(
          onCreateAccount: () => setState(() => _showSignUp = true),
        );
      },
    );
  }
}
