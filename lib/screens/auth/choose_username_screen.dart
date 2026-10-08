import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/glass_card.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class ChooseUsernameScreen extends StatefulWidget {
  const ChooseUsernameScreen({super.key});

  @override
  State<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends State<ChooseUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _userService = UserService();

  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameFeedback;

  @override
  void initState() {
    super.initState();
    // Pre-suggest initial username from Google email or display name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.firebaseUser;
      if (user != null) {
        String suggestion = '';
        if (user.email != null && user.email!.contains('@')) {
          suggestion = user.email!.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
        } else if (user.displayName != null) {
          suggestion = user.displayName!.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
        }
        if (suggestion.isNotEmpty && suggestion.length >= 3) {
          _usernameController.text = suggestion;
          _onUsernameChanged(suggestion);
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final clean = value.trim().toLowerCase().replaceAll('@', '');

    if (clean.length < 3) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameFeedback = null;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameFeedback = 'Checking availability...';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final available = await _userService.isUsernameAvailable(clean);
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
          _usernameFeedback = available ? 'Username available ✓' : 'Username already taken ✗';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _usernameFeedback = null;
        });
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a different username. This one is taken.'),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final normalized = _usernameController.text.trim().toLowerCase().replaceAll('@', '');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.completeGoogleSignUp(username: normalized);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final googleUser = authProvider.firebaseUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cyan.withOpacity(0.25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Google User Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.liquidPrimaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: googleUser?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  googleUser!.photoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Choose Your Username',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Welcome ${googleUser?.displayName ?? "there"}! Pick your unique @handle for Shizz.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),

                      GlassCard(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connected Google Account pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.glassWhiteVeryLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.Side(color: AppTheme.glassBorder),
                              ),
                              child: Row(
                                children: [
                                  Image.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      googleUser?.email ?? 'Google Account',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Username Input
                            TextFormField(
                              controller: _usernameController,
                              onChanged: _onUsernameChanged,
                              validator: (val) {
                                final clean = val?.trim().toLowerCase().replaceAll('@', '');
                                return Validators.validateUsername(clean);
                              },
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                  color: AppTheme.cyan,
                                  size: 20,
                                ),
                                labelText: 'Unique Username',
                                hintText: 'your_handle',
                                hintStyle: const TextStyle(color: AppTheme.textMuted),
                                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                suffixIcon: _isCheckingUsername
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
                                        ),
                                      )
                                    : _isUsernameAvailable != null
                                    ? Icon(
                                        _isUsernameAvailable! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        color: _isUsernameAvailable! ? AppTheme.emerald : AppTheme.rose,
                                        size: 20,
                                      )
                                    : null,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _isUsernameAvailable == false
                                        ? AppTheme.rose
                                        : AppTheme.glassBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppTheme.primary),
                                ),
                                filled: true,
                                fillColor: AppTheme.glassWhiteVeryLow,
                              ),
                            ),

                            // Availability feedback
                            if (_usernameFeedback != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _usernameFeedback!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isUsernameAvailable == true
                                      ? AppTheme.emerald
                                      : _isUsernameAvailable == false
                                      ? AppTheme.rose
                                      : AppTheme.cyan,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.liquidPrimaryGradient,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Start Chatting on Shizz',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Cancel / Sign out button
                            Center(
                              child: TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                        await authProvider.signOut();
                                        if (mounted) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                            (route) => false,
                                          );
                                        }
                                      },
                                child: const Text(
                                  'Use a different account / Cancel',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }
}
