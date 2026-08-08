import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/mandi_service.dart';
import '../../models/other_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class MandiRatesScreen extends StatefulWidget {
  const MandiRatesScreen({super.key});

  @override
  State<MandiRatesScreen> createState() => _MandiRatesScreenState();
}

class _MandiRatesScreenState extends State<MandiRatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mandiSvc = MandiService();
  String _selectedCity = AppConstants.cities.first;
  MandiRate? _expandedRate;
  Map<String, dynamic>? _priceSuggestion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mandiSvc.seedSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getPriceSuggestion(MandiRate rate) async {
    final suggestion = await _mandiSvc.getPriceSuggestion(
        rate.cropName, _selectedCity);
    setState(() {
      _expandedRate = rate;
      _priceSuggestion = suggestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mandi Rates 📊'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primaryGreen,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '  Rates  '),
            Tab(text: '  Price Suggestion  '),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                icon: const Icon(Icons.location_on_outlined,
                    size: 18, color: AppTheme.primaryGreen),
                style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                items: AppConstants.cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedCity = v!;
                  _expandedRate = null;
                  _priceSuggestion = null;
                }),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RatesTab(
            selectedCity: _selectedCity,
            mandiSvc: _mandiSvc,
            expandedRate: _expandedRate,
            priceSuggestion: _priceSuggestion,
            onRateTap: _getPriceSuggestion,
          ),
          _PriceSuggestionTab(
            mandiSvc: _mandiSvc,
            selectedCity: _selectedCity,
          ),
        ],
      ),
    );
  }
}

// ── Rates Tab ─────────────────────────────────────────────────────────────────
class _RatesTab extends StatelessWidget {
  final String selectedCity;
  final MandiService mandiSvc;
  final MandiRate? expandedRate;
  final Map<String, dynamic>? priceSuggestion;
  final Future<void> Function(MandiRate) onRateTap;

  const _RatesTab({
    required this.selectedCity,
    required this.mandiSvc,
    required this.expandedRate,
    required this.priceSuggestion,
    required this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MandiRate>>(
      stream: mandiSvc.getMandiRates(city: selectedCity),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }
        final rates = snap.data ?? [];
        if (rates.isEmpty) {
          return _emptyState(context, selectedCity);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: rates.length +
              (expandedRate != null ? 1 : 0),
          itemBuilder: (_, i) {
            // Insert chart+suggestion after tapped card
            if (expandedRate != null) {
              final idx = rates.indexWhere((r) => r.id == expandedRate!.id);
              if (idx >= 0 && i == idx + 1) {
                return _ExpandedChart(
                  rate: expandedRate!,
                  suggestion: priceSuggestion,
                );
              }
              if (i > idx + 1) {
                return _RateCard(
                    rate: rates[i - 1], onTap: () => onRateTap(rates[i - 1]));
              }
            }
            final rateIdx = expandedRate != null
                ? (i <= rates.indexWhere((r) => r.id == expandedRate!.id)
                    ? i
                    : i - 1)
                : i;
            if (rateIdx >= rates.length) return const SizedBox();
            final rate = rates[rateIdx];
            return _RateCard(
              rate: rate,
              isSelected: expandedRate?.id == rate.id,
              onTap: () => onRateTap(rate),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, String city) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📊', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No mandi data yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Load sample mandi rates for all major Pakistan cities to get started.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await mandiSvc.seedSampleData();
              messenger.showSnackBar(const SnackBar(
                content: Text('✅ Sample mandi data loaded!'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.download_for_offline_outlined),
            label: const Text('Load Sample Data'),
          ),
        ]),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final MandiRate rate;
  final bool isSelected;
  final VoidCallback onTap;

  const _RateCard({
    required this.rate,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final up = rate.isTrendUp;
    final changeColor = up ? AppTheme.successGreen : AppTheme.errorRed;
    final cropColor = Color(AppConstants.getCropColor(rate.cropName));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
            width: isSelected ? 2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Crop icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cropColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  AppConstants.getCropEmoji(rate.cropName),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rate.cropName,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${rate.city}  •  per ${rate.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('Tap to see trend & suggestion',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen.withOpacity(0.7))),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                'PKR ${rate.pricePerUnit.toStringAsFixed(0)}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(up ? Icons.trending_up : Icons.trending_down,
                    color: changeColor, size: 14),
                const SizedBox(width: 2),
                Text(
                  '${rate.changeAmount.abs().toStringAsFixed(0)} (${rate.changePercent.abs().toStringAsFixed(1)}%)',
                  style: TextStyle(
                      color: changeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 2),
              Icon(
                isSelected ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.textMedium,
                size: 18,
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ExpandedChart extends StatelessWidget {
  final MandiRate rate;
  final Map<String, dynamic>? suggestion;

  const _ExpandedChart({required this.rate, this.suggestion});

  @override
  Widget build(BuildContext context) {
    final prices = rate.last7Days;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final minV = prices.isEmpty
        ? 0.0
        : prices.reduce((a, b) => a < b ? a : b) * 0.97;
    final maxV = prices.isEmpty
        ? 100.0
        : prices.reduce((a, b) => a > b ? a : b) * 1.03;
    final isUp = rate.isTrendUp;
    final lineColor = isUp ? AppTheme.successGreen : AppTheme.errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1),
      ),
      child: Column(children: [
        // Chart header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('7-Day Price Trend',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: lineColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down,
                        color: lineColor, size: 14),
                    const SizedBox(width: 3),
                    Text(isUp ? 'Rising' : 'Falling',
                        style: TextStyle(
                            color: lineColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ]),
                ),
              ]),
        ),

        // Line chart
        if (prices.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: SizedBox(
              height: 150,
              child: LineChart(LineChartData(
                minY: minV,
                maxY: maxV,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(v.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 9, color: AppTheme.textMedium)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox();
                        }
                        return Text(days[i],
                            style: const TextStyle(
                                fontSize: 9, color: AppTheme.textMedium));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: prices.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: lineColor,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.textDark.withOpacity(0.85),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              'PKR ${s.y.toStringAsFixed(0)}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ))
                        .toList(),
                  ),
                ),
              )),
            ),
          ),

        // Price suggestion box
        if (suggestion != null) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Price Suggestion',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (suggestion!['shouldSell'] == true
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (suggestion!['shouldSell'] == true
                                ? AppTheme.successGreen
                                : AppTheme.warningOrange)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      suggestion!['recommendation'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: suggestion!['shouldSell'] == true
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                          height: 1.5),
                    ),
                  ),
                  if (suggestion!['currentPrice'] != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      _PriceTag(
                          label: 'Today',
                          value:
                              'PKR ${(suggestion!['currentPrice'] as double).toStringAsFixed(0)}',
                          color: AppTheme.primaryGreen),
                      const SizedBox(width: 10),
                      _PriceTag(
                          label: '7-Day Avg',
                          value:
                              'PKR ${(suggestion!['avgPrice'] as double).toStringAsFixed(0)}',
                          color: AppTheme.textMedium),
                    ]),
                  ],
                ]),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen.withOpacity(0.5))),
              const SizedBox(width: 10),
              const Text('Loading suggestion...'),
            ]),
          ),
      ]),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PriceTag(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textMedium)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }
}

// ── Price Suggestion Tab ──────────────────────────────────────────────────────
class _PriceSuggestionTab extends StatefulWidget {
  final MandiService mandiSvc;
  final String selectedCity;

  const _PriceSuggestionTab(
      {required this.mandiSvc, required this.selectedCity});

  @override
  State<_PriceSuggestionTab> createState() => _PriceSuggestionTabState();
}

class _PriceSuggestionTabState extends State<_PriceSuggestionTab> {
  String _selectedCrop = 'Wheat';
  Map<String, dynamic>? _suggestion;
  bool _loading = false;

  Future<void> _getSuggestion() async {
    setState(() {
      _loading = true;
      _suggestion = null;
    });
    final s = await widget.mandiSvc.getPriceSuggestion(
        _selectedCrop, widget.selectedCity);
    setState(() {
      _suggestion = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final crops = AppConstants.cropCategories.where((c) => c != 'All').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI Price Suggestion 🤖',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
            'Get smart recommendation — should you sell now or wait?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textMedium)),
        const SizedBox(height: 20),

        // Crop picker
        Text('Select Crop',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: crops.map((crop) {
            final sel = crop == _selectedCrop;
            final color = Color(AppConstants.getCropColor(crop));
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCrop = crop);
                _suggestion = null;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.12) : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? color : AppTheme.divider,
                      width: sel ? 2 : 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(AppConstants.getCropEmoji(crop),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                  Text(crop,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? color : AppTheme.textDark)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _getSuggestion,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(_loading
                ? 'Analyzing...'
                : 'Get Suggestion for $_selectedCrop'),
          ),
        ),
        const SizedBox(height: 20),

        if (_suggestion != null) ...[
          // Result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _suggestion!['shouldSell'] == true
                    ? [AppTheme.successGreen.withOpacity(0.1),
                        AppTheme.accentGreen.withOpacity(0.05)]
                    : [AppTheme.warningOrange.withOpacity(0.1),
                        AppTheme.amber.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _suggestion!['shouldSell'] == true
                    ? AppTheme.successGreen.withOpacity(0.4)
                    : AppTheme.warningOrange.withOpacity(0.4),
              ),
            ),
            child: Column(children: [
              Text(
                _suggestion!['shouldSell'] == true ? '✅ SELL NOW' : '⏳ WAIT',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _suggestion!['shouldSell'] == true
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange),
              ),
              const SizedBox(height: 12),
              Text(
                _suggestion!['recommendation'] ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              if (_suggestion!['currentPrice'] != null) ...[
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _BigStat(
                    label: 'Current Price',
                    value:
                        'PKR ${(_suggestion!['currentPrice'] as double).toStringAsFixed(0)}',
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  _BigStat(
                    label: '7-Day Average',
                    value:
                        'PKR ${(_suggestion!['avgPrice'] as double).toStringAsFixed(0)}',
                    color: AppTheme.textMedium,
                  ),
                ]),
              ],
            ]),
          ),
        ],

        const SizedBox(height: 24),
        // Demand indicator
        Text('🔥 High Demand Crops',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Based on recent orders across Pakistan',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _getDemandData(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen));
            }
            final demand = snap.data!;
            if (demand.isEmpty) {
              return const Text('No demand data yet');
            }
            return Column(
              children: demand.entries.take(5).map((e) {
                final max =
                    demand.values.reduce((a, b) => a > b ? a : b) as int;
                final pct = (e.value as int) / max;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Text(AppConstants.getCropEmoji(e.key),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text('${e.value} orders',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor:
                                    AppTheme.primaryGreen.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryGreen),
                              ),
                            ),
                          ]),
                    ),
                  ]),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  Future<Map<String, dynamic>> _getDemandData() async {
    // Mock demand data — in production, use product_service.getDemandIndicator()
    return {
      'Wheat': 45,
      'Rice': 38,
      'Tomato': 32,
      'Potato': 28,
      'Onion': 22,
    };
  }
}

class _BigStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _BigStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMedium),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
