import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../services/offline_queue.dart';
import 'report_screen.dart';
import 'tickets_screen.dart';
import 'ai_chat_screen.dart';
import 'campus_pulse_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReportScreen(),
    TicketsScreen(),
    AiChatScreen(),
    CampusPulseScreen(),
  ];

  void _showSosDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.criticalBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.criticalText.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.emergency_rounded, color: AppTheme.criticalText, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'CAMPUS EMERGENCY SOS',
                style: GoogleFonts.merriweather(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.criticalText,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Presidency University Rapid Hazard Response Protocols',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              _sosActionTile(
                icon: Icons.shield_rounded,
                title: 'Campus Security Control Room',
                subtitle: '+91 80 4925 5555 • Ext. 100 (24x7 Security)',
                badgeColor: AppTheme.criticalBg,
                textColor: AppTheme.criticalText,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calling Campus Security Control Room (Ext. 100)...'),
                      backgroundColor: AppTheme.primaryRoyalNavy,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _sosActionTile(
                icon: Icons.local_hospital_rounded,
                title: 'Medical Center & Ambulance',
                subtitle: 'Hostel Ground Floor • Ext. 108',
                badgeColor: AppTheme.highBg,
                textColor: AppTheme.highText,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calling Campus Health Center & Ambulance (Ext. 108)...'),
                      backgroundColor: AppTheme.primaryRoyalNavy,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _sosActionTile(
                icon: Icons.bolt_rounded,
                title: 'High-Voltage & Fire Emergency Desk',
                subtitle: 'Central Plant & Power Substation • Ext. 120',
                badgeColor: AppTheme.mediumBg,
                textColor: AppTheme.mediumText,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alerting Substation Rapid Isolation Crew (Ext. 120)...'),
                      backgroundColor: AppTheme.primaryRoyalNavy,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Dismiss SOS', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sosActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.crispIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.call_rounded, size: 18, color: AppTheme.primaryRoyalNavy),
      ),
    );
  }

  void _showOfflineQueueDialog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: OfflineQueue.getQueue(),
            builder: (context, snap) {
              final queue = snap.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Offline Incident Queue',
                        style: GoogleFonts.merriweather(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.highBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.highText.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${queue.length} Pending',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.highText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reports stored locally when network is unavailable. Auto-syncs when online.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  if (queue.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_done_rounded, color: AppTheme.lowText, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'All incident reports are fully synchronized with the campus server.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppTheme.lowText, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...queue.take(3).map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.crispIvory,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 18, color: AppTheme.primaryRoyalNavy),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item['title']} (${item['building']})',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: queue.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await provider.syncOfflineQueueNow();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Offline reports successfully synced with CampusFlow Server!'),
                                    backgroundColor: AppTheme.lowText,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text('Sync All Pending Now', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRoyalNavy,
                        foregroundColor: AppTheme.purePorcelain,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, Map<String, dynamic>? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRoyalNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondaryRoyalGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (user?['name'] as String? ?? 'S').isNotEmpty
                        ? (user!['name'] as String)[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.merriweather(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondaryRoyalGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?['name'] as String? ?? 'Campus Member',
                style: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                user?['email'] as String? ?? 'student@presidencyuniversity.in',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  'Role: ${user?['role'] as String? ?? 'CAMPUS_MEMBER'} • Presidency Operations Node',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRoyalNavy),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context.read<AppProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                  label: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.criticalText,
                    foregroundColor: AppTheme.purePorcelain,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    final user = provider.user;

    return Scaffold(
      backgroundColor: AppTheme.crispIvory,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primaryRoyalNavy,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.secondaryRoyalGold,
                width: 2.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0F294A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.purePorcelain,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.secondaryRoyalGold,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/images/presidency_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded,
                          color: AppTheme.primaryRoyalNavy,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CampusFlow AI',
                          style: GoogleFonts.merriweather(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.2,
                            color: AppTheme.purePorcelain,
                          ),
                        ),
                        Text(
                          'Presidency University Operations Portal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondaryRoyalGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Emergency SOS Button
                  GestureDetector(
                    onTap: () => _showSosDialog(context),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.criticalText.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emergency_rounded, size: 14, color: AppTheme.criticalText),
                          const SizedBox(width: 4),
                          Text(
                            'SOS',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.criticalText),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Live Status Pill
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: provider.isOnline ? AppTheme.lowBg : AppTheme.highBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: provider.isOnline ? AppTheme.lowText.withValues(alpha: 0.3) : AppTheme.highText.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: provider.isOnline ? AppTheme.lowText : AppTheme.highText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.isOnline ? 'LIVE' : 'LOCAL',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: provider.isOnline ? AppTheme.lowText : AppTheme.highText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Offline Queue Badge
                  FutureBuilder<int>(
                    future: OfflineQueue.pendingCount,
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => _showOfflineQueueDialog(context, provider),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.highBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.highText.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_upload_rounded, size: 14, color: AppTheme.highText),
                              const SizedBox(width: 4),
                              Text(
                                '$count',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.highText),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Profile Avatar Button
                  GestureDetector(
                    onTap: () => _showProfileDialog(context, user),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.purePorcelain.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.secondaryRoyalGold, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          (user?['name'] as String? ?? 'S').isNotEmpty
                              ? (user!['name'] as String)[0].toUpperCase()
                              : 'S',
                          style: GoogleFonts.inter(
                            color: AppTheme.secondaryRoyalGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.purePorcelain,
          border: Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D0F294A),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.add_circle_outline_rounded,
                  activeIcon: Icons.add_circle_rounded,
                  label: 'Report',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavBarItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Tickets',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavBarItem(
                  icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy_rounded,
                  label: 'Copilot',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavBarItem(
                  icon: Icons.monitor_heart_outlined,
                  activeIcon: Icons.monitor_heart_rounded,
                  label: 'Pulse',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRoyalNavy.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
