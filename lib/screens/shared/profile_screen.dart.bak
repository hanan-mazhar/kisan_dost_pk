import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.editProfile),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 28, horizontal: 20),
            color: AppTheme.cardWhite,
            child: Column(children: [
              _Avatar(user: user),
              const SizedBox(height: 12),
              Text(user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: user.role == AppConstants.roleAdmin
                      ? Colors.red.withOpacity(0.1)
                      : AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleLabel(user.role),
                  style: TextStyle(
                      color: user.role == AppConstants.roleAdmin
                          ? Colors.red.shade700
                          : AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              if (user.rating > 0) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star_rounded,
                      color: AppTheme.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${user.rating.toStringAsFixed(1)} (${user.totalRatings} reviews)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ]),
              ],
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _InfoCard(title: 'Contact Info', items: [
                _Item(Icons.phone_outlined, 'Phone',
                    user.phoneNumber.isEmpty ? '—' : user.phoneNumber),
                _Item(Icons.email_outlined, 'Email', user.email),
                _Item(Icons.location_city_outlined, 'City', user.city),
              ]),
              const SizedBox(height: 12),
              if (user.walletNumber != null)
                _InfoCard(title: 'Payment Info', items: [
                  _Item(Icons.account_balance_wallet_outlined,
                      'Easypaisa / JazzCash', user.walletNumber!),
                ]),
              if (user.walletNumber != null) const SizedBox(height: 12),
              // Admin Panel shortcut - only for admin
              if (user.role == AppConstants.roleAdmin) ...[
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.adminHome),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(children: [
                      Text('🛡️', style: TextStyle(fontSize: 26)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin Panel',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              Text(
                                  'Users, Products, Orders & Mandi manage karein',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ]),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 16),
                    ]),
                  ),
                ),
              ],
              _MenuCard(items: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.notifications),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Row(children: [
                        Text('🎧', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10),
                        Text('Help & Support'),
                      ]),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kisi bhi maslay ke liye hamse rabta karein:',
                              style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                          SizedBox(height: 16),
                          _ContactRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: 'hananmazhar01@gmail.com',
                          ),
                          SizedBox(height: 10),
                          _ContactRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: '0321-1108694',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'About ${AppConstants.appName}',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Row(children: [
                        Text('🌾', style: TextStyle(fontSize: 26)),
                        SizedBox(width: 10),
                        Text('Kisan Dost PK'),
                      ]),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Version 1.0.0',
                              style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                          SizedBox(height: 16),
                          Divider(),
                          SizedBox(height: 12),
                          Text(
                            'Developed by @ 2026 Hanan Mazhar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout,
                      color: AppTheme.errorRed, size: 18),
                  label: const Text('Logout',
                      style: TextStyle(color: AppTheme.errorRed)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorRed)),
                ),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ]),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case AppConstants.roleFarmer:
        return '👨‍🌾 Farmer';
      case AppConstants.roleBuyer:
        return '🛒 Buyer';
      case AppConstants.roleTransporter:
        return '🚚 Transporter';
      case AppConstants.roleAdmin:
        return '🛡️ Admin';
      default:
        return role;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (_) => false);
    }
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final UserModel user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (user.profileImageUrl != null) {
      final f = File(user.profileImageUrl!);
      if (f.existsSync()) {
        img = FileImage(f);
      } else if (user.profileImageUrl!.startsWith('http')) {
        img = NetworkImage(user.profileImageUrl!);
      }
    }

    return CircleAvatar(
      radius: 46,
      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
      backgroundImage: img,
      child: img == null
          ? Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen),
            )
          : null,
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _Item {
  final IconData icon;
  final String label, value;
  _Item(this.icon, this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child:
              Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const Divider(height: 1),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(children: [
                Icon(item.icon,
                    size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(item.value,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ]),
              ]),
            )),
      ]),
    );
  }
}

// ── Menu Card ─────────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.onTap});
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: items
            .map((item) => ListTile(
                  leading: Icon(item.icon, color: AppTheme.primaryGreen),
                  title: Text(item.label,
                      style: Theme.of(context).textTheme.bodyLarge),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textMedium),
                  onTap: item.onTap,
                ))
            .toList(),
      ),
    );
  }
}

// ── Edit Profile Screen ───────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _walletCtrl;
  final _citySearchCtrl = TextEditingController();
  String _selectedCity = 'Lahore';
  File? _newImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _nameCtrl = TextEditingController(text: user.fullName);
    _phoneCtrl = TextEditingController(text: user.phoneNumber);
    _walletCtrl = TextEditingController(text: user.walletNumber ?? '');
    _selectedCity = user.city;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _walletCtrl.dispose();
    _citySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _newImage = File(img.path));
  }

  Future<String?> _saveImageLocally(
      String userId, File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest =
        File('${dir.path}/profiles/$userId.jpg');
    await dest.parent.create(recursive: true);
    await image.copy(dest.path);
    return dest.path;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser!;

    String? imgPath = user.profileImageUrl;
    if (_newImage != null) {
      imgPath = await _saveImageLocally(user.id, _newImage!);
    }

    final updated = user.copyWith(
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      city: _selectedCity,
      walletNumber: _walletCtrl.text.trim().isEmpty
          ? null
          : _walletCtrl.text.trim(),
      profileImageUrl: imgPath,
    );

    await authProvider.updateUser(updated);
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Profile updated!'),
      backgroundColor: AppTheme.successGreen,
    ));
    Navigator.pop(context);
  }

  void _showCityPicker() {
    _citySearchCtrl.clear();
    List<String> filtered = List.from(AppConstants.allPakistanCities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
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
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.background,
                ),
                onChanged: (q) {
                  setS(() {
                    filtered = q.isEmpty
                        ? List.from(AppConstants.allPakistanCities)
                        : AppConstants.allPakistanCities
                            .where((c) => c
                                .toLowerCase()
                                .contains(q.toLowerCase()))
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
                    leading: Icon(Icons.location_city_outlined,
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.textMedium,
                        size: 20),
                    title: Text(city,
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textDark)),
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
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    ImageProvider? currentImg;
    if (_newImage != null) {
      currentImg = FileImage(_newImage!);
    } else if (user.profileImageUrl != null) {
      final f = File(user.profileImageUrl!);
      currentImg = f.existsSync() ? FileImage(f) : null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Avatar picker
          GestureDetector(
            onTap: _pickImage,
            child: Stack(children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                backgroundImage: currentImg,
                child: currentImg == null
                    ? Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Text('Tap to change photo',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),

          CustomTextField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'Your full name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            hint: '03XX XXXXXXX',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),

          // City Picker
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
              child: Row(children: [
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
                        Text(_selectedCity,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                      ]),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: AppTheme.textMedium),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _walletCtrl,
            label: 'Easypaisa / JazzCash Number',
            hint: 'For receiving payments',
            prefixIcon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 28),
          LoadingButton(
            label: 'Save Changes',
            isLoading: _isLoading,
            onPressed: _save,
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Contact Row widget used in Help & Support dialog ─────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
      ]),
    ]);
  }
}
