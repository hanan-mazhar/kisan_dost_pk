import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();
  final _citySearchCtrl = TextEditingController();

  String _selectedRole = AppConstants.roleFarmer;
  String _selectedCity = 'Lahore';
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _walletCtrl.dispose();
    _citySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      role: _selectedRole,
      city: _selectedCity,
      walletNumber: _walletCtrl.text.trim().isEmpty
          ? null
          : _walletCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && auth.currentUser != null) {
      _navigateByRole(auth.currentUser!.role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Signup failed. Please try again.'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateByRole(String role) {
    String route;
    switch (role) {
      case AppConstants.roleFarmer:
        route = AppRoutes.farmerHome;
        break;
      case AppConstants.roleBuyer:
        route = AppRoutes.buyerHome;
        break;
      case AppConstants.roleTransporter:
        route = AppRoutes.transporterHome;
        break;
      default:
        route = AppRoutes.buyerHome;
    }
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  // City picker with search
  void _showCityPicker() {
    _citySearchCtrl.clear();
    List<String> filtered = List.from(AppConstants.allPakistanCities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Select City',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _citySearchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppTheme.background,
                  ),
                  onChanged: (q) {
                    setS(() {
                      filtered = AppConstants.allPakistanCities
                          .where((c) =>
                              c.toLowerCase().contains(q.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final city = filtered[i];
                    final isSelected = city == _selectedCity;
                    return ListTile(
                      leading: Icon(
                        Icons.location_city_outlined,
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.textMedium,
                        size: 20,
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textDark,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.primaryGreen, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedCity = city);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width > 600 ? size.width * 0.15 : 20,
          vertical: 8,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join ${AppConstants.appName} today',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textMedium),
              ),
              const SizedBox(height: 20),

              // ── Role Selection ────────────────────────────────────────────
              Text('I am a...',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RoleChip(
                    emoji: '👨‍🌾',
                    label: 'Farmer',
                    subtitle: 'Grow & sell produce',
                    value: AppConstants.roleFarmer,
                    selected: _selectedRole,
                    onTap: (v) => setState(() => _selectedRole = v),
                  ),
                  const SizedBox(width: 8),
                  _RoleChip(
                    emoji: '🛒',
                    label: 'Buyer',
                    subtitle: 'Buy agricultural products',
                    value: AppConstants.roleBuyer,
                    selected: _selectedRole,
                    onTap: (v) => setState(() => _selectedRole = v),
                  ),
                  const SizedBox(width: 8),
                  _RoleChip(
                    emoji: '🚚',
                    label: 'Transporter',
                    subtitle: 'Provide logistics',
                    value: AppConstants.roleTransporter,
                    selected: _selectedRole,
                    onTap: (v) => setState(() => _selectedRole = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Personal Info ─────────────────────────────────────────────
              CustomTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Ahmad Khan',
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 3) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: '03XX XXXXXXX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  final cleaned = v.trim().replaceAll(' ', '');
                  if (cleaned.length < 10) return 'Enter valid Pakistani number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'ahmad@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── City Picker ───────────────────────────────────────────────
              GestureDetector(
                onTap: _showCityPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city_outlined,
                          color: AppTheme.textMedium, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('City',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMedium)),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCity,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: AppTheme.textMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Password ──────────────────────────────────────────────────
              CustomTextField(
                controller: _passCtrl,
                label: 'Password',
                hint: 'Minimum 6 characters',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textMedium,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Wallet (Optional) ─────────────────────────────────────────
              CustomTextField(
                controller: _walletCtrl,
                label: 'Easypaisa / JazzCash Number (Optional)',
                hint: 'For receiving payments',
                prefixIcon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppTheme.textMedium),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Add your mobile wallet number to receive digital payments from buyers.',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textMedium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────────────────
              LoadingButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _signup,
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role Chip Widget ──────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _RoleChip({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.08)
                : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isSelected ? AppTheme.primaryGreen : AppTheme.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 9,
                    color: isSelected
                        ? AppTheme.primaryGreen.withOpacity(0.7)
                        : AppTheme.textMedium),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
