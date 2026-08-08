import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _orb1Ctrl;
  late AnimationController _orb2Ctrl;

  late Animation<double> _logoBounce;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _loadFade;
  late Animation<double> _orb1Scale;
  late Animation<double> _orb2Scale;

  @override
  void initState() {
    super.initState();

    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _orb1Ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _orb2Ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

    _logoBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.35, curve: Curves.easeIn)));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.45, 0.75, curve: Curves.easeOut)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.45, 0.80, curve: Curves.easeOut)));
    _loadFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.75, 1.0, curve: Curves.easeOut)));
    _orb1Scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _orb1Ctrl, curve: Curves.easeInOut));
    _orb2Scale = Tween<double>(begin: 1.0, end: 0.80).animate(
        CurvedAnimation(parent: _orb2Ctrl, curve: Curves.easeInOut));

    _bgCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoCtrl.forward();
    });
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (!mounted) return;
    if (!onboarded) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (auth.isAuthenticated && auth.currentUser != null) {
      switch (auth.currentUser!.role) {
        case AppConstants.roleFarmer:      Navigator.pushReplacementNamed(context, AppRoutes.farmerHome); break;
        case AppConstants.roleBuyer:       Navigator.pushReplacementNamed(context, AppRoutes.buyerHome); break;
        case AppConstants.roleAdmin:       Navigator.pushReplacementNamed(context, AppRoutes.adminHome); break;
        case AppConstants.roleTransporter: Navigator.pushReplacementNamed(context, AppRoutes.transporterHome); break;
        default: Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _orb1Ctrl.dispose();
    _orb2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A3D24), Color(0xFF1A7A4A), Color(0xFF25A96A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Floating orbs
            AnimatedBuilder(
              animation: _orb1Scale,
              builder: (_, __) => Positioned(
                top: -size.height * 0.08,
                right: -size.width * 0.15,
                child: Transform.scale(
                  scale: _orb1Scale.value,
                  child: Container(
                    width: size.width * 0.75,
                    height: size.width * 0.75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _orb2Scale,
              builder: (_, __) => Positioned(
                bottom: -size.height * 0.08,
                left: -size.width * 0.20,
                child: Transform.scale(
                  scale: _orb2Scale.value,
                  child: Container(
                    width: size.width * 0.85,
                    height: size.width * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFB300).withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Glass orb small accent
            Positioned(
              top: size.height * 0.18,
              left: 32,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.62,
              right: 24,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                  ),
                ),
              ),
            ),

            
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    ScaleTransition(
                      scale: _logoBounce,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.40),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 40,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: SvgPicture.asset('assets/images/splash_logo.svg'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App name + tagline
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                                  ),
                                  child: Text(
                                    AppConstants.appTagline,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Loader
                    FadeTransition(
                      opacity: _loadFade,
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.75)),
                          strokeWidth: 2.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
