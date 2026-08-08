import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/other_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';



class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _svc = AdminService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Admin Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            if (admin != null)
              Text(admin.fullName,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w400)),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primaryGreen,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 17), text: 'Overview', iconMargin: EdgeInsets.only(bottom: 2)),
            Tab(icon: Icon(Icons.people_rounded, size: 17), text: 'Users', iconMargin: EdgeInsets.only(bottom: 2)),
            Tab(icon: Icon(Icons.storefront_rounded, size: 17), text: 'Products', iconMargin: EdgeInsets.only(bottom: 2)),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 17), text: 'Orders', iconMargin: EdgeInsets.only(bottom: 2)),
            Tab(icon: Icon(Icons.show_chart_rounded, size: 17), text: 'Mandi', iconMargin: EdgeInsets.only(bottom: 2)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(svc: _svc),
          _UsersTab(svc: _svc),
          _ProductsTab(svc: _svc),
          _OrdersTab(svc: _svc),
          _MandiTab(svc: _svc),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 1 — OVERVIEW
// ════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final AdminService svc;
  const _OverviewTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: svc.getStats(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }
        final s = snap.data!;
        return RefreshIndicator(
          onRefresh: () async => (ctx as Element).markNeedsBuild(),
          color: AppTheme.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('🌾', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Kisan Dost PK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('Live Admin Dashboard', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    _HeroNum(icon: '👥', label: 'Users', value: '${s['total_users']}'),
                    const SizedBox(width: 10),
                    _HeroNum(icon: '🌾', label: 'Products', value: '${s['products']}'),
                    const SizedBox(width: 10),
                    _HeroNum(icon: '📦', label: 'Orders', value: '${s['orders']}'),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // Users breakdown
              const _SectionTitle('Users by Role'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _RoleCard(emoji: '👨‍🌾', role: 'Farmers', count: s['farmers'] ?? 0, color: AppTheme.primaryGreen)),
                const SizedBox(width: 10),
                Expanded(child: _RoleCard(emoji: '🛒', role: 'Buyers', count: s['buyers'] ?? 0, color: const Color(0xFF1565C0))),
                const SizedBox(width: 10),
                Expanded(child: _RoleCard(emoji: '🚛', role: 'Transporters', count: s['transporters'] ?? 0, color: AppTheme.warningOrange)),
              ]),
              const SizedBox(height: 20),

              // Stats
              const _SectionTitle('Platform Stats'),
              const SizedBox(height: 10),
              _StatRow(icon: Icons.store_rounded, label: 'Total Products', value: '${s['products']}'),
              _StatRow(icon: Icons.shopping_bag_rounded, label: 'Total Orders', value: '${s['orders']}'),
              _StatRow(icon: Icons.pending_actions_rounded, label: 'Pending Orders', value: '${s['pending_orders']}', valueColor: AppTheme.warningOrange),
              _StatRow(icon: Icons.bar_chart_rounded, label: 'Mandi Rate Entries', value: '${s['mandi_rates']}'),
              _StatRow(icon: Icons.block_rounded, label: 'Banned Users', value: '${s['banned']}', valueColor: AppTheme.errorRed),
              const SizedBox(height: 20),

              // Quick actions
              const _SectionTitle('Quick Actions'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.refresh_rounded,
                label: 'Reseed Sample Mandi Data',
                subtitle: '9 crops × 8 cities — fresh sample prices',
                color: AppTheme.primaryGreen,
                onTap: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  showDialog(context: context, barrierDismissible: false,
                      builder: (_) => const AlertDialog(
                        content: Row(children: [
                          CircularProgressIndicator(color: AppTheme.primaryGreen),
                          SizedBox(width: 16), Text('Reseeding mandi data...'),
                        ]),
                      ));
                  await AdminService().reseedMandiData();
                  nav.pop();
                  messenger.showSnackBar(const SnackBar(
                    content: Text('✅ Mandi data reseeded (72 entries)'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 2 — USERS
// ════════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatefulWidget {
  final AdminService svc;
  const _UsersTab({required this.svc});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _role = 'All';
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search name, email, city, phone...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _ctrl.clear(); setState(() => _search = ''); })
                  : null,
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Farmer', 'Buyer', 'Transporter', 'Admin', 'Banned'].map((r) {
                final sel = _role == r;
                Color chipColor = AppTheme.primaryGreen;
                if (r == 'Buyer') chipColor = const Color(0xFF1565C0);
                if (r == 'Transporter') chipColor = AppTheme.warningOrange;
                if (r == 'Admin') chipColor = Colors.purple;
                if (r == 'Banned') chipColor = AppTheme.errorRed;
                return GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? chipColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? chipColor : AppTheme.divider),
                    ),
                    child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppTheme.textDark)),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: StreamBuilder<List<UserModel>>(
          stream: widget.svc.watchAllUsers(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
            }
            var users = snap.data ?? [];
            if (_role == 'Banned') {
              users = users.where((u) => u.isBanned).toList();
            } else if (_role != 'All') {
              users = users.where((u) => u.role.toLowerCase() == _role.toLowerCase()).toList();
            }
            if (_search.isNotEmpty) {
              users = users.where((u) =>
                u.fullName.toLowerCase().contains(_search) ||
                u.email.toLowerCase().contains(_search) ||
                u.city.toLowerCase().contains(_search) ||
                u.phoneNumber.contains(_search)).toList();
            }
            if (users.isEmpty) {
              return _EmptyState(emoji: '👥', text: _search.isNotEmpty ? 'No results for "$_search"' : 'No users here');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _UserCard(user: users[i], svc: widget.svc),
            );
          },
        ),
      ),
    ]);
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final AdminService svc;
  const _UserCard({required this.user, required this.svc});

  Color get _rc {
    switch (user.role) {
      case 'farmer': return AppTheme.primaryGreen;
      case 'buyer': return const Color(0xFF1565C0);
      case 'transporter': return AppTheme.warningOrange;
      case 'admin': return Colors.purple;
      default: return AppTheme.textMedium;
    }
  }
  String get _re {
    switch (user.role) {
      case 'farmer': return '👨‍🌾'; case 'buyer': return '🛒';
      case 'transporter': return '🚛'; case 'admin': return '🛡️';
      default: return '👤';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: user.isBanned ? AppTheme.errorRed.withOpacity(0.4) : AppTheme.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: _rc.withOpacity(0.12), shape: BoxShape.circle),
                child: Center(child: Text(_re, style: const TextStyle(fontSize: 24))),
              ),
              if (user.isBanned)
                Positioned(right: 0, bottom: 0, child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                  child: const Icon(Icons.block, size: 10, color: Colors.white),
                )),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: _rc.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                  child: Text(user.role.toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _rc)),
                ),
              ]),
              const SizedBox(height: 3),
              _DetailLine(icon: Icons.email_outlined, text: user.email),
              _DetailLine(icon: Icons.phone_outlined, text: user.phoneNumber),
              _DetailLine(icon: Icons.location_on_outlined, text: user.city),
              if (user.walletNumber != null && user.walletNumber!.isNotEmpty)
                _DetailLine(icon: Icons.account_balance_wallet_outlined, text: user.walletNumber!),
              _DetailLine(
                icon: Icons.calendar_today_outlined,
                text: 'Joined: ${_fmt(user.createdAt)}',
              ),
              if (user.rating > 0)
                Row(children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppTheme.warningOrange),
                  const SizedBox(width: 3),
                  Text(user.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.warningOrange)),
                  Text(' (${user.totalRatings} ratings)',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMedium)),
                ]),
            ])),
          ]),
        ),
        // Actions row
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(children: [
            Expanded(child: _Btn(
              icon: Icons.swap_horiz_rounded, label: 'Change Role', color: AppTheme.primaryGreen,
              onTap: () => _showRoleDialog(context),
            )),
            const SizedBox(width: 8),
            Expanded(child: _Btn(
              icon: user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
              label: user.isBanned ? 'Unban' : 'Ban',
              color: user.isBanned ? AppTheme.successGreen : AppTheme.errorRed,
              onTap: () => _toggleBan(context),
            )),
            const SizedBox(width: 8),
            _Btn(
              icon: Icons.delete_outline_rounded, label: '', color: AppTheme.errorRed,
              onTap: () => _deleteUser(context), iconOnly: true,
            ),
          ]),
        ),
      ]),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showRoleDialog(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Change Role\n${user.fullName}', style: const TextStyle(fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min,
        children: ['farmer', 'buyer', 'transporter', 'admin'].map((r) =>
          RadioListTile<String>(
            value: r, groupValue: user.role,
            activeColor: AppTheme.primaryGreen,
            dense: true,
            title: Text(r[0].toUpperCase() + r.substring(1), style: const TextStyle(fontSize: 14)),
            onChanged: (v) async {
              Navigator.pop(ctx);
              await svc.changeUserRole(user.id, v!);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text('✅ ${user.fullName} is now a $v'),
                backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating,
              ));
              }
            },
          )).toList(),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
    ));
  }

  void _toggleBan(BuildContext ctx) async {
    final ban = !user.isBanned;
    final ok = await _confirm(ctx,
      title: ban ? 'Ban ${user.fullName}?' : 'Unban ${user.fullName}?',
      body: ban ? 'User will be flagged as banned.' : 'User will be restored to normal.',
      confirmLabel: ban ? 'Ban' : 'Unban',
      danger: ban,
    );
    if (ok) {
      await svc.setBanStatus(user.id, ban);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(ban ? '🚫 ${user.fullName} banned' : '✅ ${user.fullName} unbanned'),
        backgroundColor: ban ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ));
      }
    }
  }

  void _deleteUser(BuildContext ctx) async {
    final ok = await _confirm(ctx,
      title: 'Delete ${user.fullName}?',
      body: 'This will permanently remove their account data. Cannot be undone.',
      confirmLabel: 'Delete', danger: true,
    );
    if (ok) {
      await svc.deleteUser(user.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('🗑️ ${user.fullName} deleted'),
        backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating,
      ));
      }
    }
  }

  Future<bool> _confirm(BuildContext ctx, {required String title, required String body,
      required String confirmLabel, required bool danger}) async {
    return await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      content: Text(body, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: danger ? AppTheme.errorRed : AppTheme.primaryGreen),
          child: Text(confirmLabel),
        ),
      ],
    )) ?? false;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — PRODUCTS
// ════════════════════════════════════════════════════════════════════════════

class _ProductsTab extends StatefulWidget {
  final AdminService svc;
  const _ProductsTab({required this.svc});
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _cat = 'All';
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search product name, farmer, city...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _ctrl.clear(); setState(() => _search = ''); })
                  : null,
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.cropCategories.map((c) {
                final sel = _cat == c;
                return GestureDetector(
                  onTap: () => setState(() => _cat = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppTheme.primaryGreen : AppTheme.divider),
                    ),
                    child: Text(c == 'All' ? 'All' : '${AppConstants.getCropEmoji(c)} $c',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppTheme.textDark)),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: StreamBuilder<List<ProductModel>>(
          stream: widget.svc.watchAllProducts(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
            }
            var products = snap.data ?? [];
            if (_cat != 'All') products = products.where((p) => p.category == _cat).toList();
            if (_search.isNotEmpty) {
              products = products.where((p) =>
                p.name.toLowerCase().contains(_search) ||
                p.farmerName.toLowerCase().contains(_search) ||
                p.location.toLowerCase().contains(_search)).toList();
            }
            if (products.isEmpty) {
              return _EmptyState(emoji: '🌾', text: _search.isNotEmpty ? 'No results for "$_search"' : 'No products found');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ProductCard(product: products[i], svc: widget.svc),
            );
          },
        ),
      ),
    ]);
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final AdminService svc;
  const _ProductCard({required this.product, required this.svc});

  @override
  Widget build(BuildContext context) {
    final cropColor = Color(AppConstants.getCropColor(product.category));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isAvailable ? AppTheme.divider : AppTheme.errorRed.withOpacity(0.35),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: cropColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(AppConstants.getCropEmoji(product.category),
                style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis)),
              if (!product.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('HIDDEN', style: TextStyle(fontSize: 9, color: AppTheme.errorRed, fontWeight: FontWeight.w800)),
                ),
            ]),
            _DetailLine(icon: Icons.person_outline_rounded, text: product.farmerName),
            _DetailLine(icon: Icons.location_on_outlined, text: product.location),
            Row(children: [
              Text('PKR ${product.pricePerUnit.toStringAsFixed(0)}/${product.unit}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
              const SizedBox(width: 10),
              Text('Qty: ${product.quantityAvailable}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
            ]),
            _DetailLine(icon: Icons.calendar_today_outlined, text: 'Added: ${_fmt(product.createdAt)}'),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Btn(
            icon: product.isAvailable ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            label: product.isAvailable ? 'Hide' : 'Unhide',
            color: product.isAvailable ? AppTheme.warningOrange : AppTheme.successGreen,
            onTap: () async {
              await svc.toggleProductAvailability(product.id, !product.isAvailable);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(product.isAvailable ? '👁️ Product hidden' : '✅ Product visible'),
                backgroundColor: AppTheme.primaryGreen, behavior: SnackBarBehavior.floating,
              ));
              }
            },
          )),
          const SizedBox(width: 8),
          _Btn(
            icon: Icons.delete_outline_rounded, label: '', color: AppTheme.errorRed,
            iconOnly: true,
            onTap: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: const Text('Delete Product?'),
                content: Text('Delete "${product.name}" by ${product.farmerName}? Cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                    child: const Text('Delete'),
                  ),
                ],
              ));
              if (ok == true) {
                await svc.deleteProduct(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🗑️ Product deleted'),
                  backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating,
                ));
                }
              }
            },
          ),
        ]),
      ]),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 4 — ORDERS
// ════════════════════════════════════════════════════════════════════════════

class _OrdersTab extends StatefulWidget {
  final AdminService svc;
  const _OrdersTab({required this.svc});
  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _status = 'All';
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final statuses = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search buyer, farmer, product...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _ctrl.clear(); setState(() => _search = ''); })
                  : null,
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: statuses.map((s) {
              final sel = _status == s;
              final color = _statusColor(s);
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? color : AppTheme.divider),
                  ),
                  child: Text('${_statusEmoji(s)} $s',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppTheme.textDark)),
                ),
              );
            }).toList()),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: StreamBuilder<List<OrderModel>>(
          stream: widget.svc.watchAllOrders(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
            }
            var orders = snap.data ?? [];
            if (_status != 'All') orders = orders.where((o) => o.status == _status).toList();
            if (_search.isNotEmpty) {
              orders = orders.where((o) =>
                o.buyerName.toLowerCase().contains(_search) ||
                o.farmerName.toLowerCase().contains(_search) ||
                o.productName.toLowerCase().contains(_search)).toList();
            }
            if (orders.isEmpty) {
              return _EmptyState(emoji: '📦', text: _search.isNotEmpty ? 'No results for "$_search"' : 'No orders found');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OrderCard(order: orders[i], svc: widget.svc),
            );
          },
        ),
      ),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending': return AppTheme.warningOrange;
      case 'Confirmed': return const Color(0xFF1565C0);
      case 'Shipped': return Colors.teal;
      case 'Delivered': return AppTheme.successGreen;
      case 'Cancelled': return AppTheme.errorRed;
      default: return AppTheme.primaryGreen;
    }
  }

  String _statusEmoji(String s) {
    switch (s) {
      case 'All': return '📋'; case 'Pending': return '⏳';
      case 'Confirmed': return '✅'; case 'Shipped': return '🚛';
      case 'Delivered': return '🎉'; case 'Cancelled': return '❌';
      default: return '📦';
    }
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final AdminService svc;
  const _OrderCard({required this.order, required this.svc});

  Color get _statusColor {
    switch (order.status) {
      case 'Pending': return AppTheme.warningOrange;
      case 'Confirmed': return const Color(0xFF1565C0);
      case 'Shipped': return Colors.teal;
      case 'Delivered': return AppTheme.successGreen;
      case 'Cancelled': return AppTheme.errorRed;
      default: return AppTheme.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(order.productName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor)),
          ),
        ]),
        const SizedBox(height: 6),
        _DetailLine(icon: Icons.person_outline_rounded, text: 'Buyer: ${order.buyerName}  •  ${order.buyerPhone}'),
        _DetailLine(icon: Icons.agriculture_outlined, text: 'Farmer: ${order.farmerName}  •  ${order.farmerPhone}'),
        _DetailLine(icon: Icons.payments_outlined, text: 'PKR ${order.totalAmount.toStringAsFixed(0)}  •  ${order.quantity} ${order.unit}  •  ${order.paymentMethod}'),
        _DetailLine(icon: Icons.location_on_outlined, text: order.deliveryAddress),
        _DetailLine(icon: Icons.calendar_today_outlined, text: 'Placed: ${_fmt(order.createdAt)}'),
        const SizedBox(height: 10),
        // Status change + delete
        Row(children: [
          Expanded(child: _Btn(
            icon: Icons.edit_rounded, label: 'Change Status', color: const Color(0xFF1565C0),
            onTap: () => _changeStatus(context),
          )),
          const SizedBox(width: 8),
          _Btn(
            icon: Icons.delete_outline_rounded, label: '', color: AppTheme.errorRed,
            iconOnly: true,
            onTap: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: const Text('Delete Order?'),
                content: Text('Delete order for "${order.productName}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                    child: const Text('Delete'),
                  ),
                ],
              ));
              if (ok == true) {
                await svc.deleteOrder(order.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🗑️ Order deleted'),
                  backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating,
                ));
                }
              }
            },
          ),
        ]),
      ]),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _changeStatus(BuildContext ctx) {
    final statuses = ['Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Update Order Status', style: TextStyle(fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min,
        children: statuses.map((s) => RadioListTile<String>(
          value: s, groupValue: order.status,
          activeColor: AppTheme.primaryGreen, dense: true,
          title: Text(s, style: const TextStyle(fontSize: 14)),
          onChanged: (v) async {
            Navigator.pop(ctx);
            await svc.updateOrderStatus(order.id, v!);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('✅ Order status → $v'),
              backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating,
            ));
            }
          },
        )).toList(),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 5 — MANDI RATES
// ════════════════════════════════════════════════════════════════════════════

class _MandiTab extends StatefulWidget {
  final AdminService svc;
  const _MandiTab({required this.svc});
  @override
  State<_MandiTab> createState() => _MandiTabState();
}

class _MandiTabState extends State<_MandiTab> {
  String _crop = 'All';
  String _city = 'All';

  @override
  Widget build(BuildContext context) {
    final cropItems = ['All', ...AppConstants.cropCategories.where((c) => c != 'All')];
    final cityItems = ['All', 'Lahore', 'Multan', 'Faisalabad', 'Karachi', 'Rawalpindi', 'Peshawar', 'Quetta', 'Hyderabad'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          Expanded(child: _DropFilter(label: 'Crop', value: _crop, items: cropItems,
              onChanged: (v) => setState(() => _crop = v))),
          const SizedBox(width: 8),
          Expanded(child: _DropFilter(label: 'City', value: _city, items: cityItems,
              onChanged: (v) => setState(() => _city = v))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAddSheet(context),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: StreamBuilder<List<MandiRate>>(
          stream: widget.svc.watchAllMandiRates(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
            }
            var rates = snap.data ?? [];
            if (_crop != 'All') rates = rates.where((r) => r.cropName == _crop).toList();
            if (_city != 'All') rates = rates.where((r) => r.city == _city).toList();

            if (rates.isEmpty) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📊', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  const Text('No mandi rates found', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSheet(context),
                    icon: const Icon(Icons.add), label: const Text('Add Rate'),
                  ),
                ]),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
              itemCount: rates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _MandiCard(rate: rates[i], svc: widget.svc),
            );
          },
        ),
      ),
    ]);
  }

  void _showAddSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMandiSheet(svc: widget.svc),
    );
  }
}

class _MandiCard extends StatelessWidget {
  final MandiRate rate;
  final AdminService svc;
  const _MandiCard({required this.rate, required this.svc});

  @override
  Widget build(BuildContext context) {
    final up = rate.isTrendUp;
    final cc = up ? AppTheme.successGreen : AppTheme.errorRed;
    final cropColor = Color(AppConstants.getCropColor(rate.cropName));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: cropColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(AppConstants.getCropEmoji(rate.cropName), style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rate.cropName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${rate.city}  •  per ${rate.unit}', style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
          Row(children: [
            Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 13, color: cc),
            const SizedBox(width: 2),
            Text('${rate.changePercent.abs().toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10, color: cc, fontWeight: FontWeight.w700)),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('PKR ${rate.pricePerUnit.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Row(children: [
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _EditMandiSheet(rate: rate, svc: svc),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.edit_rounded, size: 13, color: AppTheme.primaryGreen),
                  SizedBox(width: 3),
                  Text('Edit', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () async {
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Delete Rate?', style: TextStyle(fontSize: 15)),
                  content: Text('Delete ${rate.cropName} rate for ${rate.city}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                      child: const Text('Delete'),
                    ),
                  ],
                ));
                if (ok == true) await svc.deleteMandiRate(rate.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.errorRed),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ── Edit Mandi Rate Sheet (with slider + text field) ─────────────────────────

class _EditMandiSheet extends StatefulWidget {
  final MandiRate rate;
  final AdminService svc;
  const _EditMandiSheet({required this.rate, required this.svc});
  @override
  State<_EditMandiSheet> createState() => _EditMandiSheetState();
}

class _EditMandiSheetState extends State<_EditMandiSheet> {
  late TextEditingController _ctrl;
  late double _sliderVal;
  late double _minVal, _maxVal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.rate.pricePerUnit;
    _sliderVal = p;
    _minVal = (p * 0.5).floorToDouble();
    _maxVal = (p * 2.0).ceilToDouble();
    _ctrl = TextEditingController(text: p.toStringAsFixed(0));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final price = double.tryParse(_ctrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Valid price required'), backgroundColor: AppTheme.errorRed,
      ));
      return;
    }
    setState(() => _loading = true);
    await widget.svc.updateMandiRate(widget.rate.id,
        newPrice: price, previousPrice: widget.rate.pricePerUnit);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ ${widget.rate.cropName} updated to PKR ${price.toStringAsFixed(0)}'),
      backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cropColor = Color(AppConstants.getCropColor(widget.rate.cropName));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        // Header
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: cropColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(AppConstants.getCropEmoji(widget.rate.cropName),
                style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.rate.cropName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text('${widget.rate.city}  •  per ${widget.rate.unit}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
          ]),
        ]),
        const SizedBox(height: 20),

        // Old price → new price
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              const Text('Current Price', style: TextStyle(fontSize: 11, color: AppTheme.textMedium)),
              const SizedBox(height: 4),
              Text('PKR ${widget.rate.pricePerUnit.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          )),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGreen, size: 22),
          ),
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Column(children: [
              const Text('New Price', style: TextStyle(fontSize: 11, color: AppTheme.textMedium)),
              const SizedBox(height: 4),
              Text('PKR ${_sliderVal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryGreen)),
            ]),
          )),
        ]),
        const SizedBox(height: 18),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryGreen,
            thumbColor: AppTheme.primaryGreen,
            inactiveTrackColor: AppTheme.primaryGreen.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _sliderVal.clamp(_minVal, _maxVal),
            min: _minVal, max: _maxVal,
            divisions: ((_maxVal - _minVal) / 10).round().clamp(1, 300),
            onChanged: (v) {
              setState(() {
                _sliderVal = v;
                _ctrl.text = v.toStringAsFixed(0);
                _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
              });
            },
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('PKR ${_minVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMedium)),
          Text('PKR ${_maxVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMedium)),
        ]),
        const SizedBox(height: 14),

        // Manual input
        TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null && parsed >= _minVal && parsed <= _maxVal) {
              setState(() => _sliderVal = parsed);
            }
          },
          decoration: InputDecoration(
            labelText: 'Enter Price (PKR)',
            prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.primaryGreen),
            suffix: Text('/ ${widget.rate.unit}', style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: Text(_loading ? 'Saving...' : 'Update Price', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Add Mandi Rate Sheet ───────────────────────────────────────────────────────

class _AddMandiSheet extends StatefulWidget {
  final AdminService svc;
  const _AddMandiSheet({required this.svc});
  @override
  State<_AddMandiSheet> createState() => _AddMandiSheetState();
}

class _AddMandiSheetState extends State<_AddMandiSheet> {
  String _crop = 'Wheat', _city = 'Lahore', _unit = '40kg';
  final _priceCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _priceCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Valid price required'), backgroundColor: AppTheme.errorRed,
      ));
      return;
    }
    setState(() => _loading = true);
    await widget.svc.addMandiRate(cropName: _crop, city: _city, price: price, unit: _unit);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $_crop rate added for $_city'),
      backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final crops = AppConstants.cropCategories.where((c) => c != 'All').toList();
    final cities = ['Lahore', 'Multan', 'Faisalabad', 'Karachi', 'Rawalpindi',
                    'Peshawar', 'Quetta', 'Hyderabad', 'Islamabad', 'Sialkot'];
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Add New Mandi Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _crop, isExpanded: true,
          decoration: InputDecoration(labelText: 'Crop',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: crops.map((c) => DropdownMenuItem(value: c,
              child: Row(children: [Text(AppConstants.getCropEmoji(c), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8), Text(c)]))).toList(),
          onChanged: (v) => setState(() => _crop = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _city, isExpanded: true,
          decoration: InputDecoration(labelText: 'City',
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _city = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(flex: 2, child: TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Price (PKR)',
                prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: _unit,
            decoration: InputDecoration(labelText: 'Unit',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: ['kg', '40kg', 'quintal', 'maund', 'ton']
                .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _unit = v!),
          )),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_rounded),
            label: Text(_loading ? 'Adding...' : 'Add Rate',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ])),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16));
}

class _HeroNum extends StatelessWidget {
  final String icon, label, value;
  const _HeroNum({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10), textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, role;
  final int count;
  final Color color;
  const _RoleCard({required this.emoji, required this.role, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(role, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _StatRow({required this.icon, required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider)),
      child: Row(children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppTheme.primaryGreen,
            fontSize: 16)),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
        ]),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Icon(icon, size: 12, color: AppTheme.textMedium),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool iconOnly;
  const _Btn({required this.icon, required this.label, required this.color, required this.onTap, this.iconOnly = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color),
          if (!iconOnly) ...[ const SizedBox(width: 4),
            Flexible(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                overflow: TextOverflow.ellipsis))],
        ]),
      ),
    );
  }
}

class _DropFilter extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _DropFilter({required this.label, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value, isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true, fillColor: Colors.white,
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji, text;
  const _EmptyState({required this.emoji, required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMedium)),
    ]));
  }
}
