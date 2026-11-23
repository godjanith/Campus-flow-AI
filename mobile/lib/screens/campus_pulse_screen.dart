import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../widgets/campus_map_view.dart';

class CampusPulseScreen extends StatefulWidget {
  const CampusPulseScreen({super.key});

  @override
  State<CampusPulseScreen> createState() => _CampusPulseScreenState();
}

class _CampusPulseScreenState extends State<CampusPulseScreen> {
  Map<String, dynamic>? _healthData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHealthScore();
  }

  Future<void> _loadHealthScore() async {
    setState(() => _isLoading = true);
    try {
      _healthData = await ApiService.getCampusHealthScore();
    } catch (_) {
      // Local calculation fallback handled in build()
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBuildingTelemetryModal(BuildContext context, String buildingName, double pct, String status, Color color) {
    HapticFeedback.lightImpact();
    final buildingData = kPresidencyBuildings.firstWhere(
      (b) => b.name == buildingName,
      orElse: () => kPresidencyBuildings[0],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppTheme.purePorcelain,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x260F294A),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRoyalNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(buildingData.icon, color: AppTheme.secondaryRoyalGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingData.name,
                          style: GoogleFonts.merriweather(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        Text(
                          buildingData.description,
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Operational Health Index:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: AppTheme.cardBorderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Campus Coordinates:', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          '${buildingData.lat}° N, ${buildingData.lng}° E',
                          style: GoogleFonts.robotoMono(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primaryRoyalNavy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Acknowledge Telemetry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRoyalNavy,
                    foregroundColor: AppTheme.purePorcelain,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
    final provider = context.watch<AppProvider>();
    final tickets = provider.tickets;

    if (_isLoading && _healthData == null && tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRoyalNavy));
    }

    final total = _healthData?['total'] as int? ?? tickets.length;
    final open = _healthData?['open'] as int? ?? tickets.where((t) => t.status == 'OPEN').length;
    final inProgress = _healthData?['inProgress'] as int? ?? tickets.where((t) => t.status == 'IN_PROGRESS').length;
    final resolved = _healthData?['resolved'] as int? ?? tickets.where((t) => t.status == 'RESOLVED').length;
    final critical = _healthData?['critical'] as int? ?? tickets.where((t) => t.severity == 'CRITICAL').length;

    int score = _healthData?['healthScore'] as int? ?? (total > 0 ? (((resolved + (inProgress * 0.5)) / total) * 100).round() : 100);

    Color scoreColor;
    Color scoreBgColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppTheme.lowText;
      scoreBgColor = AppTheme.lowBg;
      scoreLabel = 'EXCELLENT';
    } else if (score >= 50) {
      scoreColor = AppTheme.highText;
      scoreBgColor = AppTheme.highBg;
      scoreLabel = 'OPERATIONAL';
    } else {
      scoreColor = AppTheme.criticalText;
      scoreBgColor = AppTheme.criticalBg;
      scoreLabel = 'NEEDS ATTENTION';
    }

    return RefreshIndicator(
      color: AppTheme.primaryRoyalNavy,
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await _loadHealthScore();
      },
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          // Screen Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRoyalNavy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TELEMETRY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.purePorcelain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live Campus Pulse',
                style: GoogleFonts.merriweather(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Official real-time infrastructure index and dispatch telemetry',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Main Gauge Card (Pure Porcelain)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.purePorcelain,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Campus Health Index',
                      style: GoogleFonts.merriweather(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        scoreLabel,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: scoreColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Radial Gauge Stack
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 12,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: GoogleFonts.merriweather(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          'SYSTEM STABLE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Automated telemetry weighted on power isolation, water lines, HVAC status, and resolution speed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Key Metrics Tiles
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.assignment_outlined,
                  label: 'Total Incidents',
                  value: '$total',
                  textColor: AppTheme.mediumText,
                  bgColor: AppTheme.mediumBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Critical Hazards',
                  value: '$critical',
                  textColor: AppTheme.criticalText,
                  bgColor: AppTheme.criticalBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.sync_rounded,
                  label: 'Open / In-Flight',
                  value: '$open / $inProgress',
                  textColor: AppTheme.highText,
                  bgColor: AppTheme.highBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Resolved Issues',
                  value: '$resolved',
                  textColor: AppTheme.lowText,
                  bgColor: AppTheme.lowBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Building Health Radar Breakdown
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.purePorcelain,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Facility Infrastructure Radar',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Tap building to inspect',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...kPresidencyBuildings.map((b) {
                  final buildingTickets = tickets.where((t) => t.building == b.name && t.status != 'RESOLVED').toList();
                  final hasCritical = buildingTickets.any((t) => t.severity == 'CRITICAL');
                  final hasHigh = buildingTickets.any((t) => t.severity == 'HIGH');

                  double pct;
                  String status;
                  Color color;

                  if (hasCritical) {
                    pct = 0.45;
                    status = 'Hazard Active';
                    color = AppTheme.criticalText;
                  } else if (hasHigh) {
                    pct = 0.70;
                    status = '${buildingTickets.length} In-Flight Action';
                    color = AppTheme.highText;
                  } else if (buildingTickets.isNotEmpty) {
                    pct = 0.85;
                    status = '${buildingTickets.length} Active Dispatch';
                    color = AppTheme.primaryRoyalNavy;
                  } else {
                    pct = 1.0;
                    status = '100% Nominal (All Clear)';
                    color = AppTheme.lowText;
                  }

                  return _buildingBar(b.name, pct, status, color);
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Socket Activity Ticker
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.purePorcelain,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.lowText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Event Dispatch Ticker',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tickets.isEmpty) ...[
                  _tickerEvent('All campus building telemetry sensors reporting nominal status.', 'Just now'),
                  _tickerEvent('Autonomous spatial dispatch standby active across all university zones.', 'Online'),
                ] else ...[
                  ...tickets.take(3).map((t) {
                    final note = t.timeline.isNotEmpty ? t.timeline.last.note : '${t.title} (${t.severity}) in ${t.building}';
                    return _tickerEvent(note, 'Active');
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildingBar(String name, double pct, String status, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showBuildingTelemetryModal(context, name, pct, status, color),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tickerEvent(String desc, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded, color: AppTheme.primaryRoyalNavy, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color bgColor;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.purePorcelain,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.merriweather(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
