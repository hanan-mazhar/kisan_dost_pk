import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/transport_service.dart';
import '../../models/other_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _transportSvc = TransportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final isTransporter = user.role == AppConstants.roleTransporter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logistics 🚚'),
        automaticallyImplyLeading: false,
        bottom: isTransporter
            ? TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.textMedium,
                indicatorColor: AppTheme.primaryGreen,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: '  Find Routes  '),
                  Tab(text: '  My Routes  '),
                ],
              )
            : null,
      ),
      floatingActionButton: isTransporter
          ? FloatingActionButton.extended(
              onPressed: () => _showAddRouteSheet(context, user),
              backgroundColor: AppTheme.primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Route',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      body: isTransporter
          ? TabBarView(controller: _tabController, children: [
              _AvailableRoutesTab(transportSvc: _transportSvc),
              _MyRoutesTab(
                  transportSvc: _transportSvc, transporterId: user.id),
            ])
          : _AvailableRoutesTab(transportSvc: _transportSvc),
    );
  }

  void _showAddRouteSheet(BuildContext context, user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddRouteSheet(transportSvc: _transportSvc, user: user),
    );
  }
}

// ── Available Routes ──────────────────────────────────────────────────────────
class _AvailableRoutesTab extends StatefulWidget {
  final TransportService transportSvc;
  const _AvailableRoutesTab({required this.transportSvc});

  @override
  State<_AvailableRoutesTab> createState() => _AvailableRoutesTabState();
}

class _AvailableRoutesTabState extends State<_AvailableRoutesTab> {
  List<TransportRoute> _routes = [];
  bool _loading = false;
  String _fromCity = '';
  String _toCity = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _routes = await widget.transportSvc.getAvailableRoutes(
      fromCity: _fromCity.isEmpty ? null : _fromCity,
      toCity: _toCity.isEmpty ? null : _toCity,
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter row
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(children: [
          Expanded(child: _CityDropdown(
            hint: 'From',
            value: _fromCity,
            onChanged: (v) { setState(() => _fromCity = v); _load(); },
          )),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward,
                color: AppTheme.primaryGreen, size: 18),
          ),
          Expanded(child: _CityDropdown(
            hint: 'To',
            value: _toCity,
            onChanged: (v) { setState(() => _toCity = v); _load(); },
          )),
        ]),
      ),
      if (_fromCity.isNotEmpty || _toCity.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() { _fromCity = ''; _toCity = ''; });
              _load();
            },
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear filters'),
          ),
        ),
      Expanded(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : _routes.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🚚', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No routes available',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Try different filters',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: _routes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _RouteCard(route: _routes[i], showContact: true),
                    ),
                  ),
      ),
    ]);
  }
}

// ── My Routes ─────────────────────────────────────────────────────────────────
class _MyRoutesTab extends StatelessWidget {
  final TransportService transportSvc;
  final String transporterId;
  const _MyRoutesTab(
      {required this.transportSvc, required this.transporterId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransportRoute>>(
      stream: transportSvc.getMyRoutes(transporterId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }
        final routes = snap.data ?? [];
        if (routes.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛣️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No routes yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tap + button to add your first route',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: routes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RouteCard(
            route: routes[i],
            showContact: false,
            onDelete: () => transportSvc.deleteRoute(routes[i].id),
            onToggle: (v) =>
                transportSvc.toggleAvailability(routes[i].id, v),
          ),
        );
      },
    );
  }
}

// ── Route Card ────────────────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final TransportRoute route;
  final bool showContact;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  const _RouteCard({
    required this.route,
    required this.showContact,
    this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Route header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🚚', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route.fromCity}  →  ${route.toCity}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(route.transporterName,
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: route.isAvailable
                  ? AppTheme.acceptedColor
                  : AppTheme.pendingColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              route.isAvailable ? 'Available' : 'Full',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: route.isAvailable
                      ? AppTheme.acceptedText
                      : AppTheme.pendingText),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Details grid
        Wrap(spacing: 16, runSpacing: 6, children: [
          _chip(Icons.calendar_today_outlined,
              DateFormat('dd MMM yyyy').format(route.departureDate)),
          _chip(Icons.inventory_2_outlined,
              '${route.availableSpaceKg.toStringAsFixed(0)} kg space'),
          _chip(Icons.payments_outlined,
              'PKR ${route.pricePerKg.toStringAsFixed(0)}/kg'),
          _chip(Icons.local_shipping_outlined, route.vehicleType),
        ]),
        const SizedBox(height: 12),

        // Actions
        Row(children: [
          if (showContact) ...[
            Expanded(
              child: _contactBtn(
                icon: Icons.call,
                label: 'Call',
                color: AppTheme.primaryGreen,
                onTap: () =>
                    launchUrl(Uri.parse('tel:${route.transporterPhone}')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _contactBtn(
                icon: Icons.message,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => launchUrl(Uri.parse(
                    'https://wa.me/92${route.transporterPhone.replaceFirst('0', '')}?text=I need transport from ${route.fromCity} to ${route.toCity}')),
              ),
            ),
          ] else ...[
            if (onToggle != null)
              Row(children: [
                Text(route.isAvailable ? 'Available' : 'Mark Unavailable',
                    style: Theme.of(context).textTheme.bodyMedium),
                Switch(
                  value: route.isAvailable,
                  onChanged: onToggle,
                  activeThumbColor: AppTheme.primaryGreen,
                ),
              ]),
            const Spacer(),
            if (onDelete != null)
              IconButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Route?'),
                      content: Text(
                          'Remove ${route.fromCity} → ${route.toCity}?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) onDelete!();
                },
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.errorRed, size: 20),
              ),
          ],
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppTheme.textMedium),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
    ]);
  }

  Widget _contactBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── City Picker Field (replaces dropdown to avoid overflow) ───────────────────
class _CityDropdown extends StatelessWidget {
  final String hint, value;
  final ValueChanged<String> onChanged;
  const _CityDropdown(
      {required this.hint, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogisticsCitySheet(hint: hint, allowAll: true),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              value.isEmpty ? 'All ($hint)' : value,
              style: TextStyle(
                fontSize: 13,
                color: value.isEmpty ? AppTheme.textMedium : AppTheme.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.search, size: 15, color: AppTheme.textMedium),
        ]),
      ),
    );
  }
}

class _LogisticsCitySheet extends StatefulWidget {
  final String hint;
  final bool allowAll;
  const _LogisticsCitySheet({required this.hint, this.allowAll = false});

  @override
  State<_LogisticsCitySheet> createState() => _LogisticsCitySheetState();
}

class _LogisticsCitySheetState extends State<_LogisticsCitySheet> {
  final _ctrl = TextEditingController();
  List<String> _filtered = AppConstants.allPakistanCities;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? AppConstants.allPakistanCities
          : AppConstants.allPakistanCities
              .where((c) => c.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Select ${widget.hint} City',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.primaryGreen),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (widget.allowAll)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(Icons.public,
                        color: AppTheme.primaryGreen, size: 20),
                    title: const Text('All cities',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                if (widget.allowAll) const Divider(height: 1),
                ..._filtered.map((city) => Column(children: [
                      ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: const Icon(Icons.location_on_outlined,
                            color: AppTheme.primaryGreen, size: 20),
                        title: Text(city,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        onTap: () => Navigator.pop(context, city),
                      ),
                      const Divider(height: 1, color: AppTheme.divider),
                    ])),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Add Route Sheet ───────────────────────────────────────────────────────────
class _AddRouteSheet extends StatefulWidget {
  final TransportService transportSvc;
  final dynamic user;
  const _AddRouteSheet({required this.transportSvc, required this.user});

  @override
  State<_AddRouteSheet> createState() => _AddRouteSheetState();
}

class _AddRouteSheetState extends State<_AddRouteSheet> {
  final _formKey = GlobalKey<FormState>();
  String _fromCity = 'Lahore';
  String _toCity = 'Karachi';
  final _spaceCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _vehicle = 'Truck';
  DateTime _departure = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void dispose() {
    _spaceCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final route = TransportRoute(
      id: '',
      transporterId: widget.user.id,
      transporterName: widget.user.fullName,
      transporterPhone: widget.user.phoneNumber,
      fromCity: _fromCity,
      toCity: _toCity,
      departureDate: _departure,
      availableSpaceKg: double.parse(_spaceCtrl.text),
      pricePerKg: double.parse(_priceCtrl.text),
      vehicleType: _vehicle,
    );

    await widget.transportSvc.addRoute(route);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Route added successfully!'),
      backgroundColor: AppTheme.successGreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Add Transport Route',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 18),

                // From / To
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const _LogisticsCitySheet(hint: 'From'),
                        );
                        if (result != null && result.isNotEmpty) setState(() => _fromCity = result);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_fromCity.isEmpty ? 'From City' : _fromCity,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _fromCity.isEmpty ? AppTheme.textMedium : AppTheme.textDark))),
                          const Icon(Icons.search, size: 14, color: AppTheme.textMedium),
                        ]),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: AppTheme.primaryGreen),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const _LogisticsCitySheet(hint: 'To'),
                        );
                        if (result != null && result.isNotEmpty) setState(() => _toCity = result);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_toCity.isEmpty ? 'To City' : _toCity,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _toCity.isEmpty ? AppTheme.textMedium : AppTheme.textDark))),
                          const Icon(Icons.search, size: 14, color: AppTheme.textMedium),
                        ]),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Departure date
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _departure,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 90)),
                    );
                    if (d != null) setState(() => _departure = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.cardWhite,
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textMedium, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Departure: ${DateFormat('dd MMM yyyy').format(_departure)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _spaceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Available (kg)',
                        prefixIcon:
                            const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Rate/kg (PKR)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _vehicle,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon:
                        const Icon(Icons.local_shipping_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Truck', 'Mini Truck', 'Pickup', 'Tractor', 'Van']
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicle = v!),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Add Route'),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}
