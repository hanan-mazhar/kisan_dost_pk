import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kisan_dost_pk/theme/app_theme.dart';
import 'package:kisan_dost_pk/utils/constants.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgOrb;
  late AnimationController _contentCtrl;
  late Animation<double> _orb;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  final _roles = [
    const _RoleData(emoji: '👨‍🌾', title: 'Farmer', subtitle: 'Apni fasal bechein', route: AppRoutes.farmerHome,
      color: AppTheme.primaryGreen, lightColor: Color(0xFFD4EDD9)),
    const _RoleData(emoji: '🛒', title: 'Buyer', subtitle: 'Seedha kisaan se kharidein', route: AppRoutes.buyerHome,
      color: AppTheme.amber, lightColor: Color(0xFFFFF8E1)),
    const _RoleData(emoji: '🚛', title: 'Transporter', subtitle: 'Transport services dein', route: AppRoutes.transporterHome,
      color: AppTheme.darkGreen, lightColor: Color(0xFFE8F5E9)),
  ];

  @override
  void initState() {
    super.initState();
    _bgOrb    = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _orb      = Tween<double>(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _bgOrb, curve: Curves.easeInOut));

    _cardFades = List.generate(3, (i) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _contentCtrl,
        curve: Interval(0.2 + i * 0.15, 0.6 + i * 0.15, curve: Curves.easeOut),
      )));
    _cardSlides = List.generate(3, (i) =>
      Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(CurvedAnimation(
        parent: _contentCtrl,
        curve: Interval(0.2 + i * 0.15, 0.65 + i * 0.15, curve: Curves.easeOut),
      )));

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _bgOrb.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A3D24), Color(0xFF1A7A4A), Color(0xFF25A96A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated orb
          AnimatedBuilder(
            animation: _orb,
            builder: (_, __) => Positioned(
              top: -size.height * 0.1,
              right: -size.width * 0.2,
              child: Transform.scale(
                scale: _orb.value,
                child: Container(
                  width: size.width,
                  height: size.width,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white.withOpacity(0.10), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom amber orb
          Positioned(
            bottom: -size.height * 0.08,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.amber.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Center(child: Text('🌾', style: TextStyle(fontSize: 44))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(AppConstants.appName,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Aap kaun hain? Role select karein',
                    style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 14, fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Role cards
                  ...List.generate(_roles.length, (i) {
                    final role = _roles[i];
                    return FadeTransition(
                      opacity: _cardFades[i],
                      child: SlideTransition(
                        position: _cardSlides[i],
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _GlassRoleCard(
                            data: role,
                            onTap: () => Navigator.pushReplacementNamed(context, role.route),
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text('⚠️ Testing Mode — Login/Signup disabled',
                            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleData {
  final String emoji, title, subtitle, route;
  final Color color, lightColor;
  const _RoleData({required this.emoji, required this.title, required this.subtitle,
    required this.route, required this.color, required this.lightColor});
}

class _GlassRoleCard extends StatefulWidget {
  final _RoleData data;
  final VoidCallback onTap;
  const _GlassRoleCard({required this.data, required this.onTap});

  @override
  State<_GlassRoleCard> createState() => _GlassRoleCardState();
}

class _GlassRoleCardState extends State<_GlassRoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _hoverScale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _hoverScale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) { _hoverCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: ScaleTransition(
        scale: _hoverScale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                        ),
                        child: Center(child: Text(widget.data.emoji, style: const TextStyle(fontSize: 28))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.data.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.data.subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12, fontWeight: FontWeight.w400)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.30)),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
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
