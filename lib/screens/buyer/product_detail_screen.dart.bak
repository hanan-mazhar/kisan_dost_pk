import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImage = 0;
  final _orderService = OrderService();

  List<String> get _allImages => [
        ...widget.product.imagePaths,
        ...widget.product.imageUrls,
      ];

  void _showOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderSheet(product: widget.product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final images = _allImages;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.cardWhite,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImage = i),
                          itemBuilder: (_, i) {
                            final path = images[i];
                            final isLocal = !path.startsWith('http');
                            if (isLocal) {
                              final f = File(path);
                              if (f.existsSync()) {
                                return Image.file(f,
                                    fit: BoxFit.cover,
                                    width: double.infinity);
                              }
                            }
                            return Image.network(
                              path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(p.category),
                            );
                          },
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: i == _currentImage ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _currentImage
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : _placeholder(p.category),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.person_outline,
                                  size: 14,
                                  color: AppTheme.textMedium),
                              const SizedBox(width: 4),
                              Text('Farmer: ${p.farmerName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ]),
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.textMedium),
                              const SizedBox(width: 4),
                              Text(p.location,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ]),
                          ],
                        ),
                      ),
                      if (p.farmerRating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              p.farmerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.lightGreenGradient,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price per ${p.unit}',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                            Text(
                              'PKR ${p.pricePerUnit.toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                      color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Available',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '${p.quantityAvailable} ${p.unit}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (p.description.isNotEmpty) ...[
                    Text('Product Details',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(p.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6)),
                    const SizedBox(height: 16),
                  ],

                  // Contact farmer
                  Text('Contact Farmer',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _ContactBtn(
                        icon: Icons.call,
                        label: 'Call',
                        color: AppTheme.primaryGreen,
                        onTap: () =>
                            launchUrl(Uri.parse('tel:${p.farmerPhone}')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ContactBtn(
                        icon: Icons.message,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => launchUrl(Uri.parse(
                            'https://wa.me/92${p.farmerPhone.replaceFirst('0', '')}?text=Assalam o Alaikum! I am interested in your ${p.name} listed on Kisan Dost PK.')),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: ElevatedButton.icon(
          onPressed: _showOrderSheet,
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text('Order Now'),
        ),
      ),
    );
  }

  Widget _placeholder(String category) {
    final color = Color(AppConstants.getCropColor(category));
    return Container(
      color: color.withOpacity(0.12),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(AppConstants.getCropEmoji(category),
              style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          Text(category,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ── Order Sheet ───────────────────────────────────────────────────────────────
class _OrderSheet extends StatefulWidget {
  final ProductModel product;
  const _OrderSheet({required this.product});

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _quantity = 1;
  String _paymentMethod = AppConstants.paymentCOD;
  bool _isLoading = false;
  String? _orderId;
  File? _paymentScreenshot;
  final _orderService = OrderService();

  double get _total => widget.product.pricePerUnit * _quantity;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().currentUser!;
    final p = widget.product;

    try {
      final order = OrderModel(
        id: '',
        productId: p.id,
        productName: p.name,
        productImageUrl: p.imagePaths.isNotEmpty ? p.imagePaths.first : '',
        farmerId: p.farmerId,
        farmerName: p.farmerName,
        farmerPhone: p.farmerPhone,
        buyerId: user.id,
        buyerName: user.fullName,
        buyerPhone: user.phoneNumber,
        pricePerUnit: p.pricePerUnit,
        unit: p.unit,
        quantity: _quantity,
        totalAmount: _total,
        status: AppConstants.statusPending,
        paymentMethod: _paymentMethod,
        deliveryAddress: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _orderId = await _orderService.placeOrder(order);
      setState(() {
        _isLoading = false;
        _step = 1;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _uploadPaymentProof() async {
    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select payment screenshot first')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Save screenshot locally
      final url = await _orderService.savePaymentProofLocally(
          _orderId!, _paymentScreenshot!);
      await _orderService.updatePayment(_orderId!, 'Paid', url);
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Order placed! Payment proof submitted.'),
        backgroundColor: AppTheme.successGreen,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorRed));
    }
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
        child: _step == 0 ? _buildForm() : _buildPayment(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
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
          Row(children: [
            Text(AppConstants.getCropEmoji(widget.product.category),
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Place Order',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(widget.product.name,
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
          ]),
          const SizedBox(height: 20),

          // Quantity
          Text('Quantity (${widget.product.unit})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Row(children: [
              IconButton(
                onPressed: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppTheme.primaryGreen),
              ),
              Expanded(
                child: Column(children: [
                  Text('$_quantity',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(widget.product.unit,
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
              IconButton(
                onPressed: () {
                  if (_quantity < widget.product.quantityAvailable) {
                    setState(() => _quantity++);
                  }
                },
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.primaryGreen),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Total
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.lightGreenGradient,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('PKR ${_total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.primaryGreen)),
                ]),
          ),
          const SizedBox(height: 14),

          // Address
          TextFormField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: 'Delivery Address',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Address required' : null,
          ),
          const SizedBox(height: 14),

          // Payment method
          Text('Payment Method',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...[
            (AppConstants.paymentCOD, '💵', 'Pay cash when delivered'),
            (AppConstants.paymentEasypaisa, '📱', 'Send via Easypaisa'),
            (AppConstants.paymentJazzCash, '💳', 'Send via JazzCash'),
            (AppConstants.paymentEscrow, '🔒', 'Secure hold payment'),
          ].map((item) => RadioListTile<String>(
                value: item.$1,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
                title: Text('${item.$2} ${item.$1}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(item.$3,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMedium)),
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppTheme.primaryGreen,
              )),
          const SizedBox(height: 12),

          // Notes
          TextFormField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Special instructions...',
              prefixIcon: const Icon(Icons.note_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Confirm Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildPayment() {
    if (_paymentMethod == AppConstants.paymentCOD) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 20),
        const Text('✅', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('Order Placed!',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Pay PKR ${_total.toStringAsFixed(0)} in cash when your order is delivered.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Track My Order'),
        ),
        const SizedBox(height: 12),
      ]);
    }

    // Easypaisa / JazzCash / Escrow
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Complete Payment',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // Step 1
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.25)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 1: Send Payment',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _payRow('Payment Method:', _paymentMethod),
                  _payRow('Send To (Farmer\'s Number):',
                      widget.product.farmerPhone),
                  _payRow('Amount:',
                      'PKR ${_total.toStringAsFixed(0)}'),
                  _payRow('Farmer Name:', widget.product.farmerName),
                ]),
          ),
          const SizedBox(height: 14),

          // Step 2 — upload screenshot
          Text('Step 2: Upload Screenshot',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final img = await picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 80);
              if (img != null) {
                setState(
                    () => _paymentScreenshot = File(img.path));
              }
            },
            child: Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _paymentScreenshot != null
                        ? AppTheme.primaryGreen
                        : AppTheme.divider,
                    width: _paymentScreenshot != null ? 2 : 1),
              ),
              child: _paymentScreenshot != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_paymentScreenshot!,
                          fit: BoxFit.cover, width: double.infinity))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_outlined,
                            size: 36,
                            color: AppTheme.primaryGreen
                                .withOpacity(0.7)),
                        const SizedBox(height: 8),
                        const Text('Tap to upload payment screenshot',
                            style: TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('From Gallery',
                            style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3: Farmer will verify payment and confirm your order.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _uploadPaymentProof,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Submit Payment Proof'),
          ),
          const SizedBox(height: 12),
        ]);
  }

  Widget _payRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMedium)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
