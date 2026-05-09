import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  late AnimationController _bgCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _bgScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _bgScale = Tween<double>(begin: 1.08, end: 1.0)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));

    _logoFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _formFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    _bgCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success && auth.currentUser != null) {
      _navigateByRole(auth.currentUser!.role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Login failed. Please try again.'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _navigateByRole(String role) {
    String route;
    switch (role) {
      case AppConstants.roleFarmer:      route = AppRoutes.farmerHome; break;
      case AppConstants.roleBuyer:       route = AppRoutes.buyerHome; break;
      case AppConstants.roleTransporter: route = AppRoutes.transporterHome; break;
      case AppConstants.roleAdmin:       route = AppRoutes.adminHome; break;
      default:                           route = AppRoutes.buyerHome;
    }
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your email to receive a reset link.'),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send Link')),
        ],
      ),
    );
    if (confirmed != true) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid email address'),
        backgroundColor: AppTheme.errorRed,
      ));
      return;
    }
    try {
      await AuthService().resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reset email sent to $email'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().contains('user-not-found') ? 'No account with this email.' : 'Failed to send reset email.'),
        backgroundColor: AppTheme.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        // Animated background decoration
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => Transform.scale(
            scale: _bgScale.value,
            child: Container(
              height: size.height * 0.42,
              decoration: AppTheme.greenGradient,
              child: Stack(children: [
                // Decorative circles
                Positioned(top: -40, right: -40,
                  child: Container(width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ))),
                Positioned(bottom: 20, left: -30,
                  child: Container(width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ))),
                Positioned(top: 60, left: 40,
                  child: Container(width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ))),
              ]),
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width > 600 ? size.width * 0.15 : 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo + Title (slides down from top)
                  FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: Center(
                        child: Column(children: [
                          Container(
                            width: 82, height: 82,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset('assets/images/splash_logo.svg'),
                          ),
                          const SizedBox(height: 16),
                          Text('Welcome Back!',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Login to ${AppConstants.appName}',
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                        ]),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.06),

                  // Form card (slides up from bottom)
                  FadeTransition(
                    opacity: _formFade,
                    child: SlideTransition(
                      position: _formSlide,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Sign In', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          const Text('Enter your credentials to continue',
                              style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _emailCtrl,
                            label: 'Email Address',
                            hint: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePass,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textMedium, size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text('Forgot Password?',
                                  style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          LoadingButton(label: 'Login', isLoading: _isLoading, onPressed: _login),
                          const SizedBox(height: 20),

                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text("Don't have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                              child: const Text('Sign Up',
                                  style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
