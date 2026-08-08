import 'package:flutter/material.dart';
import 'package:kisan_dost_pk/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../models/other_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class OrdersScreen extends StatefulWidget {
  final bool isFarmer;
  const OrdersScreen({super.key, required this.isFarmer});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderService = OrderService();
  final _tabs = ['All', 'Pending', 'Accepted', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primaryGreen,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: widget.isFarmer
            ? _orderService.getFarmerOrders(user.id)
            : _orderService.getBuyerOrders(user.id),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📋', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Could not load orders',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().contains('index')
                        ? 'Database index missing. Please check Firestore console.'
                        : snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            );
          }
          final all = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final filtered = tab == 'All'
                  ? all
                  : all.where((o) => o.status == tab).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📦',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                          'No ${tab == 'All' ? '' : tab.toLowerCase()} orders',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (_, i) => _OrderCard(
                  order: filtered[i],
                  isFarmer: widget.isFarmer,
                  orderService: _orderService,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isFarmer;
  final OrderService orderService;

  const _OrderCard({
    required this.order,
    required this.isFarmer,
    required this.orderService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Text(AppConstants.getCropEmoji(order.productName),
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(order.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              StatusBadge(status: order.status),
            ]),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(context, '👤',
                      isFarmer
                          ? 'Buyer: ${order.buyerName}'
                          : 'Farmer: ${order.farmerName}'),
                  const SizedBox(height: 4),
                  _row(context, '📦',
                      '${order.quantity} ${order.unit} × PKR ${order.pricePerUnit.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  _row(context, '💰',
                      'Total: PKR ${order.totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  _row(context, '💳',
                      '${order.paymentMethod}  •  ${order.paymentStatus}'),
                  const SizedBox(height: 4),
                  _row(context, '📍', order.deliveryAddress),
                  if (order.notes != null &&
                      order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _row(context, '📝', order.notes!),
                  ],

                  // Payment proof (local file)
                  if (order.paymentProofPath != null &&
                      order.paymentProofPath!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _viewProof(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBluee.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.infoBluee
                                  .withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.receipt_outlined,
                              color: AppTheme.infoBluee, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment screenshot submitted — tap to view',
                              style: TextStyle(
                                  color: AppTheme.infoBluee,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppTheme.infoBluee, size: 18),
                        ]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _buildActions(context),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String emoji, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _buildActions(BuildContext context) {
    final phone = isFarmer ? order.buyerPhone : order.farmerPhone;

    return Wrap(spacing: 8, runSpacing: 8, children: [
      _Btn(
        icon: Icons.call_outlined,
        label: 'Call',
        color: AppTheme.primaryGreen,
        onTap: () => launchUrl(Uri.parse('tel:$phone')),
      ),
      _Btn(
        icon: Icons.chat_outlined,
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        onTap: () => launchUrl(Uri.parse(
            'https://wa.me/92${phone.replaceFirst('0', '')}?text=Regarding my order: ${order.productName}')),
      ),

      // Farmer: accept / reject pending
      if (isFarmer && order.status == AppConstants.statusPending) ...[
        _Btn(
          icon: Icons.check_circle_outline,
          label: 'Accept',
          color: AppTheme.successGreen,
          onTap: () =>
              _updateStatus(context, AppConstants.statusAccepted),
        ),
        _Btn(
          icon: Icons.cancel_outlined,
          label: 'Reject',
          color: AppTheme.errorRed,
          onTap: () =>
              _updateStatus(context, AppConstants.statusRejected),
        ),
      ],

      // Farmer: mark delivered
      if (isFarmer && order.status == AppConstants.statusAccepted)
        _Btn(
          icon: Icons.local_shipping_outlined,
          label: 'Mark Delivered',
          color: AppTheme.infoBluee,
          onTap: () =>
              _updateStatus(context, AppConstants.statusDelivered),
        ),

      // Farmer: verify payment
      if (isFarmer &&
          order.paymentStatus == 'Paid' &&
          order.paymentProofPath != null)
        _Btn(
          icon: Icons.verified_outlined,
          label: 'Verify Payment',
          color: AppTheme.amber,
          onTap: () async {
            await orderService.verifyPayment(order.id, buyerId: order.buyerId, productName: order.productName);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ Payment verified!'),
                    backgroundColor: AppTheme.successGreen),
              );
            }
          },
        ),

      // Buyer: rate after delivery
      if (!isFarmer &&
          order.status == AppConstants.statusDelivered &&
          !order.isRated)
        _Btn(
          icon: Icons.star_outline,
          label: 'Rate Farmer',
          color: AppTheme.amber,
          onTap: () => _showRatingDialog(context),
        ),
    ]);
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    await orderService.updateOrderStatus(order.id, status, buyerId: order.buyerId, productName: order.productName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order $status'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _viewProof(BuildContext context) {
    final path = order.paymentProofPath!;
    final isUrl = path.startsWith('http');

    // Purana local path — doosre device pe nahi milega
    if (!isUrl) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Payment Proof'),
          content: const Text(
            'Yeh screenshot purane format mein save tha aur sirf us device pe tha jis se upload hua tha. Naye orders mein screenshot har device pe nazar aayega.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Theek Hai'),
            ),
          ],
        ),
      );
      return;
    }

    // Cloudinary URL — har device pe dikhega
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppBar(
            title: const Text('Payment Proof'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Image.network(
            path,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Screenshot load nahi ho saki'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    double rating = 4;
    final reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Rate Farmer'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('How was your experience with ${order.farmerName}?',
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setS(() => rating = i + 1.0),
                  child: Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.amber,
                    size: 38,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewCtrl,
              decoration: const InputDecoration(
                hintText: 'Write a review (optional)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user =
                    context.read<AuthProvider>().currentUser;
                if (user == null) return;
                final u = user;
                await orderService.submitRating(RatingModel(
                  id: '',
                  orderId: order.id,
                  farmerId: order.farmerId,
                  buyerId: u.id,
                  buyerName: u.fullName,
                  rating: rating,
                  review: reviewCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('⭐ Rating submitted!'),
                        backgroundColor: AppTheme.successGreen),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ]),
      ),
    );
  }
}
