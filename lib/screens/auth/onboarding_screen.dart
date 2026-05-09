import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = [
    const _Page(
      image: 'assets/images/onboard1.svg',
      emoji: '👨‍🌾',
      title: 'Sell Directly to Buyers',
      subtitle:
          'Reach thousands of buyers across Pakistan and get better prices for your produce — no middlemen.',
      color: AppTheme.primaryGreen,
    ),
    const _Page(
      image: 'assets/images/onboard2.svg',
      emoji: '📊',
      title: 'Track Mandi Prices',
      subtitle:
          'Get real-time mandi rates and price trends to make smarter selling decisions.',
      color: AppTheme.darkGreen,
    ),
    const _Page(
      image: 'assets/images/onboard3.svg',
      emoji: '🚚',
      title: 'Easy Logistics',
      subtitle:
          'Find reliable transport partners and deliver your produce anywhere in Pakistan.',
      color: AppTheme.primaryGreen,
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration
                      Container(
                        width: size.width * 0.55,
                        height: size.width * 0.55,
                        decoration: BoxDecoration(
                          color: p.color.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SvgPicture.asset(
                            p.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        p.subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                                color: AppTheme.textMedium,
                                height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppTheme.primaryGreen
                      : AppTheme.textLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Next / Get Started button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: () {
                if (_page < _pages.length - 1) {
                  _ctrl.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _finish();
                }
              },
              child: Text(
                  _page < _pages.length - 1 ? 'Next →' : 'Get Started'),
            ),
          ),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}

class _Page {
  final String image, emoji, title, subtitle;
  final Color color;
  const _Page(
      {required this.image,
      required this.emoji,
      required this.title,
      required this.subtitle,
      required this.color});
}
