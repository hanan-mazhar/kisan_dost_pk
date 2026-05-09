import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _notifs = [
    _Notif('📦', 'New Order Received',
        'You received a new order for Wheat (80 bags) from Ahmed Khan.',
        '2 min ago', false, 'order'),
    _Notif('💰', 'Price Alert 🔥',
        'Wheat price is 18% above 7-day average in Lahore! Good time to sell.',
        '1 hour ago', false, 'price'),
    _Notif('✅', 'Order Delivered',
        'Your order #1234 has been successfully delivered to buyer.',
        'Yesterday', true, 'order'),
    _Notif('🚚', 'Transport Available',
        'New transport route: Lahore → Multan on 25 May. 2000 kg space.',
        '2 days ago', true, 'transport'),
    _Notif('⭐', 'New Rating Received',
        'Raheel Khan gave you 5 stars! "Excellent quality wheat."',
        '3 days ago', true, 'rating'),
    _Notif('📉', 'Price Drop Alert',
        'Tomato prices dropped 12% in Karachi mandi today.',
        '4 days ago', true, 'price'),
    _Notif('🎉', 'Welcome to Kisan Dost PK!',
        'Your account is ready. Start adding products to sell.',
        '1 week ago', true, 'system'),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _notifs.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 14),
                    Text('No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium),
                  ]))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotifCard(
                notif: _notifs[i],
                onTap: () => setState(() => _notifs[i].read = true),
              ),
            ),
    );
  }
}

class _Notif {
  final String emoji, title, body, time, type;
  bool read;
  _Notif(this.emoji, this.title, this.body, this.time, this.read, this.type);
}

class _NotifCard extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  Color get _typeColor {
    switch (notif.type) {
      case 'order': return AppTheme.primaryGreen;
      case 'price': return AppTheme.amber;
      case 'transport': return AppTheme.infoBluee;
      case 'rating': return AppTheme.warningOrange;
      default: return AppTheme.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: notif.read
              ? AppTheme.cardWhite
              : AppTheme.primaryGreen.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.read
                ? AppTheme.divider
                : AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(notif.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                              fontWeight: notif.read
                                  ? FontWeight.w500
                                  : FontWeight.w700),
                        ),
                      ),
                      if (!notif.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notif.time,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight),
                    ),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
