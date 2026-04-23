import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/organic_background.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String? initialToken;

  const VerifyEmailPage({super.key, required this.email, this.initialToken});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _tokenController = TextEditingController();
  bool _verifying = false;
  bool _checkingStatus = false;
  bool _resending = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final initialToken = widget.initialToken ?? '';
    if (initialToken.isNotEmpty) {
      _tokenController.text = initialToken;
      _message =
          'Development mode: verification token is prefilled. Tap Verify Email.';
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String _extractVerificationToken(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return '';

    final uri = Uri.tryParse(raw);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return (uri.queryParameters['token'] ?? '').trim();
    }

    return raw;
  }

  Future<void> _verifyEmail() async {
    final token = _extractVerificationToken(_tokenController.text);

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste the verification token or full link'),
        ),
      );
      return;
    }

    _tokenController.text = token;

    setState(() => _verifying = true);

    final success = await context.read<AuthService>().verifyEmail(token);

    if (!mounted) return;
    setState(() => _verifying = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired verification code')),
      );
    }
  }

  Future<void> _checkLinkVerificationStatus() async {
    setState(() => _checkingStatus = true);

    final isVerified = await context
        .read<AuthService>()
        .checkEmailVerificationStatus();

    if (!mounted) return;
    setState(() => _checkingStatus = false);

    if (isVerified == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already verified. Redirecting...')),
      );
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    if (isVerified == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not verified yet. Click the link in your email, then try again.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not check verification status right now.'),
      ),
    );
  }

  Future<void> _resendEmail() async {
    setState(() => _resending = true);

    final result = await context.read<AuthService>().resendVerificationEmail(
      widget.email,
    );

    if (!mounted) return;
    setState(() => _resending = false);

    if (result == null || result['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send verification email')),
      );
      return;
    }

    final devVerificationToken = (result['devVerificationToken'] ?? '')
        .toString();
    if (devVerificationToken.isNotEmpty) {
      _tokenController.text = devVerificationToken;
      setState(
        () => _message =
            'Development mode: verification token is prefilled. Tap Verify Email.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Development token loaded. Tap Verify Email.'),
        ),
      );
      return;
    }

    setState(() => _message = 'Verification email sent! Check your inbox.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification email sent!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NutritionBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 16),
                // Header
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification email to ${widget.email}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Click the verification link in your email. You can also paste the full link below.',
                ),
                const SizedBox(height: 28),

                // Message (if any)
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(color: Colors.green.shade900),
                    ),
                  ),
                const SizedBox(height: 20),

                // Verification Code Input
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: 'Verification Token or Link',
                    hintText: 'Paste token or full verification URL',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.mail),
                  ),
                ),
                const SizedBox(height: 24),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _verifying ? null : _verifyEmail,
                    icon: const Icon(Icons.check_circle),
                    label: Text(_verifying ? 'Verifying...' : 'Verify Email'),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkingStatus
                        ? null
                        : _checkLinkVerificationStatus,
                    icon: const Icon(Icons.mark_email_read),
                    label: Text(
                      _checkingStatus
                          ? 'Checking...'
                          : 'I Clicked The Link In Email',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend Email Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _resending ? null : _resendEmail,
                    icon: const Icon(Icons.refresh),
                    label: Text(_resending ? 'Sending...' : 'Resend Email'),
                  ),
                ),
                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✓ Why verify your email?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Secure your account\n'
                        '• Receive important updates\n'
                        '• Enable password reset\n'
                        '• Unlock all features',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
