import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kisan_dost_pk/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../shared/mandi_rates_screen.dart';
import '../shared/orders_screen.dart';
import '../shared/profile_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});
  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _navCtrl;

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _navCtrl.forward();
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _BuyerMarketplace(),
      const MandiRatesScreen(),
      const OrdersScreen(isFarmer: false),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: IndexedStack(key: ValueKey(_currentTab), index: _currentTab, children: tabs),
      ),
      bottomNavigationBar: _ModernNavBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        items: const [
          _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Market'),
          _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Mandi'),
          _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
          _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Modern Nav Bar ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _ModernNavBar({required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          key: ValueKey(selected),
                          color: selected ? AppTheme.primaryGreen : AppTheme.textMedium,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? AppTheme.primaryGreen : AppTheme.textMedium,
                          )),
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

// ── Buyer Marketplace ─────────────────────────────────────────────────────────
class _BuyerMarketplace extends StatefulWidget {
  const _BuyerMarketplace();
  @override
  State<_BuyerMarketplace> createState() => _BuyerMarketplaceState();
}

class _BuyerMarketplaceState extends State<_BuyerMarketplace> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedCity = '';
  List<ProductModel> _products = [];
  bool _isLoading = false;
  final _citySearchCtrl = TextEditingController();
  final _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _citySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    _products = await _productService.getProducts(
      category: _selectedCategory,
      city: _selectedCity.isEmpty ? null : _selectedCity,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    setState(() => _isLoading = false);
  }

  void _showCityPicker() {
    _citySearchCtrl.clear();
    List<String> filtered = ['All Cities', ...AppConstants.allPakistanCities];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text('Filter by City', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (_selectedCity.isNotEmpty)
                  TextButton(
                    onPressed: () { setState(() => _selectedCity = ''); Navigator.pop(ctx); _loadProducts(); },
                    child: const Text('Clear', style: TextStyle(color: AppTheme.errorRed)),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _citySearchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search any city...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true, fillColor: AppTheme.background,
                ),
                onChanged: (q) => setS(() {
                  filtered = q.isEmpty
                      ? ['All Cities', ...AppConstants.allPakistanCities]
                      : AppConstants.allPakistanCities.where((c) => c.toLowerCase().contains(q.toLowerCase())).toList();
                }),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final city = filtered[i];
                  final isAll = city == 'All Cities';
                  final isSelected = isAll ? _selectedCity.isEmpty : _selectedCity == city;
                  return ListTile(
                    leading: Icon(isAll ? Icons.public : Icons.location_city_outlined,
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.textMedium, size: 20),
                    title: Text(city, style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20) : null,
                    onTap: () { setState(() => _selectedCity = isAll ? '' : city); Navigator.pop(ctx); _loadProducts(); },
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
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          // Modern Header
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Marketplace', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    if (user != null)
                      Text('Salam, ${user.fullName.split(' ').first}! 👋',
                          style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
                  ]),
                ),
                // City filter
                GestureDetector(
                  onTap: _showCityPicker,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedCity.isNotEmpty ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _selectedCity.isNotEmpty ? AppTheme.primaryGreen : AppTheme.divider),
                    ),
                    child: Row(children: [
                      Icon(Icons.location_on_rounded, size: 13,
                          color: _selectedCity.isNotEmpty ? AppTheme.primaryGreen : AppTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(_selectedCity.isEmpty ? 'All Pakistan' : _selectedCity,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _selectedCity.isNotEmpty ? AppTheme.primaryGreen : AppTheme.textMedium)),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16,
                          color: _selectedCity.isNotEmpty ? AppTheme.primaryGreen : AppTheme.textMedium),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    icon: const Icon(Icons.notifications_outlined, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search crops, farmers, location...',
                    hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMedium, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { _searchCtrl.clear(); _loadProducts(); })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  onSubmitted: (_) => _loadProducts(),
                  onChanged: (v) { if (v.isEmpty) _loadProducts(); setState(() {}); },
                ),
              ),
              const SizedBox(height: 10),

              // Category chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.cropCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = AppConstants.cropCategories[i];
                    final selected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () { setState(() => _selectedCategory = cat); _loadProducts(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primaryGreen : AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppTheme.primaryGreen : AppTheme.divider),
                          boxShadow: selected ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
                        ),
                        child: Row(children: [
                          Text(AppConstants.getCropEmoji(cat), style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppTheme.textMedium)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ]),
          ),

          // Results count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_products.length} products',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                ),
                if (_selectedCity.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('in $_selectedCity',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                ],
              ]),
            ),

          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _products.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('🔍', style: TextStyle(fontSize: 52)),
                          const SizedBox(height: 12),
                          Text('No products found', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () { setState(() { _selectedCategory = 'All'; _selectedCity = ''; _searchCtrl.clear(); }); _loadProducts(); },
                            child: const Text('Clear all filters'),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: AppTheme.primaryGreen,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, childAspectRatio: 0.72,
                            crossAxisSpacing: 10, mainAxisSpacing: 10,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (_, i) => FadeInWidget(
                            delayMs: (i * 50).clamp(0, 300),
                            child: _ProductGridCard(product: _products[i]),
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// ── Product Grid Card ─────────────────────────────────────────────────────────
class _ProductGridCard extends StatefulWidget {
  final ProductModel product;
  const _ProductGridCard({required this.product});
  @override
  State<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<_ProductGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _pressScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: Container(
          decoration: AppTheme.elevatedCardDecoration,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(children: [
                  _productImage(product),
                  // Category badge
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(AppConstants.getCropEmoji(product.category),
                          style: const TextStyle(fontSize: 12)),
                    )),
                ]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 11, color: AppTheme.textLight),
                    const SizedBox(width: 2),
                    Expanded(child: Text(product.location,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PKR ${product.pricePerUnit.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('/${product.unit}', style: const TextStyle(fontSize: 9, color: AppTheme.textLight)),
                    ])),
                    if (product.farmerRating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.star_rounded, size: 11, color: AppTheme.amber),
                          const SizedBox(width: 2),
                          Text(product.farmerRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.amber)),
                        ]),
                      ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _productImage(ProductModel product) {
    if (product.imagePaths.isNotEmpty) {
      final f = File(product.imagePaths.first);
      if (f.existsSync()) return Image.file(f, width: double.infinity, fit: BoxFit.cover);
    }
    if (product.imageUrls.isNotEmpty) {
      return Image.network(product.imageUrls.first, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(product.category));
    }
    return _placeholder(product.category);
  }

  Widget _placeholder(String category) {
    final color = Color(AppConstants.getCropColor(category));
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(
        colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      )),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(AppConstants.getCropEmoji(category), style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 4),
        Text(category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
