import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../shared/mandi_rates_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/logistics_screen.dart';
import '../shared/orders_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _FarmerDashboard(),
      const MandiRatesScreen(),
      const OrdersScreen(isFarmer: true),
      const LogisticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentTab, children: tabs),
      bottomNavigationBar: _FarmerNavBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
      ),
    );
  }
}

class _FarmerDashboard extends StatelessWidget {
  const _FarmerDashboard();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _fmt(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final productSvc = ProductService();
    final orderSvc = OrderService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Gradient Header ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                  decoration: AppTheme.greenGradient,
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_greeting(),
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Hello, ${user?.fullName.split(' ').first ?? 'Farmer'} 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'F',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),

                // ── Stats ────────────────────────────────────────────────────
                FutureBuilder<Map<String, dynamic>>(
                  future: orderSvc.getFarmerEarnings(user?.id ?? ''),
                  builder: (ctx, snap) {
                    final earnings =
                        (snap.data?['totalEarnings'] ?? 0.0)
                            as double;
                    final orders =
                        (snap.data?['totalOrders'] ?? 0) as int;
                    return Row(children: [
                      _StatCard(
                        label: 'Total Earnings',
                        value: 'PKR ${_fmt(earnings)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Delivered',
                        value: orders.toString(),
                        icon: Icons.check_circle_outline,
                        color: AppTheme.infoBluee,
                      ),
                    ]);
                  },
                ),
                const SizedBox(height: 18),

                // ── Quick Actions ────────────────────────────────────────────
                Text('Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _QuickAction(
                      emoji: '➕',
                      label: 'Add\nProduct',
                      color: AppTheme.primaryGreen,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.addProduct),
                    ),
                    _QuickAction(
                      emoji: '📊',
                      label: 'Mandi\nRates',
                      color: AppTheme.infoBluee,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.mandiRates),
                    ),
                    _QuickAction(
                      emoji: '📦',
                      label: 'Orders',
                      color: AppTheme.amber,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.orders,
                          arguments: true),
                    ),
                    _QuickAction(
                      emoji: '🚚',
                      label: 'Logistics',
                      color: AppTheme.warningOrange,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.logistics),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── My Products ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Products',
                        style:
                            Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.addProduct),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<ProductModel>>(
                  stream: productSvc
                      .getFarmerProducts(user?.id ?? ''),
                  builder: (ctx, snap) {
                    if (snap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen));
                    }
                    final products = snap.data ?? [];
                    if (products.isEmpty) {
                      return _EmptyProducts(
                          onAdd: () => Navigator.pushNamed(
                              context, AppRoutes.addProduct));
                    }
                    return Column(
                      children: products
                          .map((p) => _ProductCard(
                              product: p,
                              onEdit: () => Navigator.pushNamed(
                                  context, AppRoutes.editProduct,
                                  arguments: p)))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Recent Orders ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Orders',
                        style:
                            Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.orders,
                          arguments: true),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<OrderModel>>(
                  stream: orderSvc
                      .getFarmerOrders(user?.id ?? ''),
                  builder: (ctx, snap) {
                    final orders =
                        (snap.data ?? []).take(3).toList();
                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration,
                        child: const Row(children: [
                          Text('📭',
                              style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Text('No orders yet'),
                        ]),
                      );
                    }
                    return Column(
                      children: orders
                          .map((o) => _RecentOrderCard(order: o))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            )),
              ])
        ),
      ),
    ));
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.emoji,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProducts({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(children: [
        const Text('🌾', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        Text('No products yet',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Add your first product to start selling',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;

  const _ProductCard({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        isThreeLine: true,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _productImage(),
        ),
        title: Text(product.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PKR ${product.pricePerUnit.toStringAsFixed(0)} / ${product.unit}',
                style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              Text(
                '${product.quantityAvailable} ${product.unit} available • ${product.location}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
            ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: product.isAvailable
                  ? AppTheme.acceptedColor
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.isAvailable ? 'Active' : 'Paused',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: product.isAvailable
                      ? AppTheme.acceptedText
                      : AppTheme.errorRed),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppTheme.textMedium),
            padding: const EdgeInsets.all(4),
          ),
        ]),
      ),
    );
  }

  Widget _productImage() {
    // Cloudinary URL first
    if (product.imageUrls.isNotEmpty) {
      return Image.network(product.imageUrls.first,
          width: 56, height: 56, fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _icon(),
          errorBuilder: (_, __, ___) => _icon());
    }
    // Fallback: old local file
    if (product.imagePaths.isNotEmpty) {
      final f = File(product.imagePaths.first);
      if (f.existsSync()) {
        return Image.file(f, width: 56, height: 56, fit: BoxFit.cover);
      }
    }
    return _icon();
  }

  Widget _icon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color:
            Color(AppConstants.getCropColor(product.category))
                .withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(AppConstants.getCropEmoji(product.category),
            style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              AppConstants.getCropEmoji(order.productName),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${order.buyerName} • PKR ${order.totalAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusBadge(status: order.status),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse('tel:${order.buyerPhone}')),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(children: [
                Icon(Icons.call_outlined,
                    size: 12, color: AppTheme.primaryGreen),
                SizedBox(width: 3),
                Text('Call',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}


// ── Modern Farmer Nav Bar ─────────────────────────────────────────────────────
class _FarmerNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FarmerNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Mandi'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
      (Icons.local_shipping_outlined, Icons.local_shipping_rounded, 'Logistics'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final (icon, activeIcon, label) = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(selected ? activeIcon : icon,
                            key: ValueKey(selected),
                            color: selected ? AppTheme.primaryGreen : AppTheme.textMedium, size: 22),
                      ),
                      const SizedBox(height: 3),
                      Text(label, style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? AppTheme.primaryGreen : AppTheme.textMedium)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
