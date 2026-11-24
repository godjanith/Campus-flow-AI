import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/ticket.dart';
import '../providers/app_provider.dart';
import '../widgets/campus_map_view.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String _scope = 'ALL'; // 'ALL' or 'MY'
  String _selectedSeverity = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allTickets = provider.tickets;
    final currentUser = provider.user;
    final currentRegNo = (currentUser?['regNo'] as String? ?? '').toLowerCase();
    final currentName = (currentUser?['name'] as String? ?? '').toLowerCase();

    // 1. Filter by Scope ("ALL" vs "MY")
    final myTickets = allTickets.where((t) {
      final tReg = t.reporterRegNo.toLowerCase().trim();
      final tName = t.reporterName.toLowerCase().trim();
      if (currentRegNo.isNotEmpty && (tReg == currentRegNo || tReg.contains(currentRegNo) || currentRegNo.contains(tReg))) return true;
      if (currentName.isNotEmpty && (tName == currentName || tName.contains(currentName) || currentName.contains(tName))) return true;
      // Also include locally issued or offline tickets created on this device
      if (t.id.startsWith('local_') || t.id.startsWith('offline_')) return true;
      return false;
    }).toList();

    final scopedTickets = _scope == 'MY' ? myTickets : allTickets;

    // 2. Filter by Search Query & Severity Pill
    final filteredTickets = scopedTickets.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.ticketCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.building.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      switch (_selectedSeverity) {
        case 'CRITICAL':
          return t.severity.toUpperCase() == 'CRITICAL';
        case 'ACTIVE':
          return t.status.toUpperCase() == 'OPEN' || t.status.toUpperCase() == 'IN_PROGRESS';
        case 'RESOLVED':
          return t.status.toUpperCase() == 'RESOLVED';
        default:
          return true;
      }
    }).toList();

    return Column(
      children: [
        // Top Filter Bar & Scope Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Column(
            children: [
              // Scope Switcher ("Campus Incidents" vs "My Submissions")
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _scope = 'ALL');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _scope == 'ALL' ? AppTheme.purePorcelain : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _scope == 'ALL'
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Campus Incidents (${allTickets.length})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: _scope == 'ALL' ? FontWeight.w700 : FontWeight.w500,
                              color: _scope == 'ALL' ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _scope = 'MY');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _scope == 'MY' ? AppTheme.purePorcelain : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _scope == 'MY'
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'My Reports (${myTickets.length})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: _scope == 'MY' ? FontWeight.w700 : FontWeight.w500,
                              color: _scope == 'MY' ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Search Input Box
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.purePorcelain,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search tickets by code, title, or building...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryRoyalNavy),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: AppTheme.textSecondary),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Severity Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip('ALL', 'All Incidents'),
                    _filterChip('CRITICAL', 'Critical Hazard', color: AppTheme.criticalText, bg: AppTheme.criticalBg),
                    _filterChip('ACTIVE', 'Active / In-Flight', color: AppTheme.highText, bg: AppTheme.highBg),
                    _filterChip('RESOLVED', 'Resolved', color: AppTheme.lowText, bg: AppTheme.lowBg),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List Body
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRoyalNavy))
              : filteredTickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                          const SizedBox(height: 10),
                          Text(
                            _scope == 'MY' ? 'No personal reports submitted yet' : 'No matching tickets found',
                            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Report an incident on the Report tab to track it here',
                            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              provider.loadTickets();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryRoyalNavy),
                            label: Text('Refresh Tickets', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryRoyalNavy)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryRoyalNavy),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryRoyalNavy,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        await provider.loadTickets();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
                        itemCount: filteredTickets.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) => _TicketCard(ticket: filteredTickets[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String filterKey, String label, {Color? color, Color? bg}) {
    final isSelected = _selectedSeverity == filterKey;
    final chipColor = color ?? AppTheme.primaryRoyalNavy;
    final chipBg = bg ?? AppTheme.mediumBg;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSeverity = filterKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? chipBg : AppTheme.purePorcelain,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? chipColor : AppTheme.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? chipColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isCritical = ticket.severity.toUpperCase() == 'CRITICAL';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.purePorcelain,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCritical ? AppTheme.criticalText.withValues(alpha: 0.4) : AppTheme.cardBorder,
          width: isCritical ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            _showDetail(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (Code, Severity, Status)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        ticket.ticketCode,
                        style: GoogleFonts.robotoMono(
                          color: AppTheme.primaryRoyalNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (ticket.id.startsWith('local_') || ticket.id.startsWith('offline_')) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.highBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.highText.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'PENDING SYNC',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.highText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _SeverityBadge(severity: ticket.severity),
                    const SizedBox(width: 6),
                    _StatusBadge(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 10),

                // Incident Title
                Text(
                  ticket.title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),

                // Location & Category
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${ticket.building} • ${ticket.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4-Stage Progress Tracker
                _TimelineProgressBar(status: ticket.status),
                const SizedBox(height: 10),

                // Footer (ETA, Time)
                Row(
                  children: [
                    const Icon(Icons.alarm_rounded, size: 14, color: AppTheme.primaryRoyalNavy),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ETA: ${ticket.estimatedResolutionTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: AppTheme.primaryRoyalNavy, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, h:mm a').format(ticket.createdAt),
                      style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketDetailSheet(ticket: ticket),
    );
  }
}

class _TimelineProgressBar extends StatelessWidget {
  final String status;
  const _TimelineProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    int activeStep = 1;
    final upper = status.toUpperCase();
    if (upper == 'OPEN') activeStep = 1;
    if (upper == 'IN_PROGRESS') activeStep = 2;
    if (upper == 'RESOLVED') activeStep = 3;

    return Row(
      children: [
        _stepDot('Reported', true),
        _stepLine(activeStep >= 2),
        _stepDot('Dispatched', activeStep >= 2),
        _stepLine(activeStep >= 3),
        _stepDot('Resolved', activeStep >= 3),
      ],
    );
  }

  Widget _stepDot(String label, bool isDone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone ? AppTheme.primaryRoyalNavy : AppTheme.cardBorderLight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
            color: isDone ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isDone ? AppTheme.primaryRoyalNavy : AppTheme.cardBorder,
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.severityColor(severity);
    final bgColor = AppTheme.severityBgColor(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            severity.toUpperCase(),
            style: GoogleFonts.inter(color: textColor, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.statusColor(status);
    final bgColor = AppTheme.statusBgColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(color: textColor, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TicketDetailSheet extends StatelessWidget {
  final Ticket ticket;
  const _TicketDetailSheet({required this.ticket});

  void _showCampusMapModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Incident Location on Campus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.merriweather(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CampusMapView(
                selectedBuilding: ticket.building,
                onBuildingSelected: (_) {},
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRoyalNavy,
                    side: const BorderSide(color: AppTheme.primaryRoyalNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close Map View'),
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
    final sevTextColor = AppTheme.severityColor(ticket.severity);
    final sevBgColor = AppTheme.severityBgColor(ticket.severity);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
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

              // Code & Copy
              Row(
                children: [
                  Text(
                    ticket.ticketCode,
                    style: GoogleFonts.robotoMono(
                      color: AppTheme.primaryRoyalNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Clipboard.setData(ClipboardData(text: ticket.ticketCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ticket code copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  _SeverityBadge(severity: ticket.severity),
                  const SizedBox(width: 6),
                  _StatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                ticket.title,
                style: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '${ticket.building} • Reported by ${ticket.reporterName} (${ticket.reporterRegNo})',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Interactive "View on Campus Map" Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCampusMapModal(context),
                  icon: const Icon(Icons.map_rounded, size: 16, color: AppTheme.primaryRoyalNavy),
                  label: Text(
                    'View ${ticket.building} on Interactive Campus Map',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryRoyalNavy),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryRoyalNavy, width: 1.2),
                    backgroundColor: AppTheme.mediumBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Role-Based Actions & Status Card
              Builder(
                builder: (context) {
                  final user = provider.user;
                  final role = (user?['role'] as String? ?? 'STUDENT').toUpperCase();
                  final isAdmin = role == 'ADMIN' || role == 'FACULTY_COORDINATOR';

                  if (isAdmin) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dispatch Operations (Admin Command):',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryRoyalGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'COMMAND ACCESS',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primaryRoyalNavy),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (ticket.status != 'IN_PROGRESS' && ticket.status != 'RESOLVED')
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      provider.updateTicketStatus(ticket.id, 'IN_PROGRESS', note: 'Technician dispatched to location.');
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.run_circle_outlined, size: 16),
                                    label: Text('Dispatch Crew', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryRoyalNavy,
                                      foregroundColor: AppTheme.purePorcelain,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              if (ticket.status == 'IN_PROGRESS') ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      provider.updateTicketStatus(ticket.id, 'RESOLVED', note: 'Repairs completed and safety verified.');
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                                    label: Text('Mark Resolved', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.lowText,
                                      foregroundColor: AppTheme.purePorcelain,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                              if (ticket.status == 'RESOLVED') ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      provider.updateTicketStatus(ticket.id, 'OPEN', note: 'Ticket reopened for follow-up inspection.');
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.replay_rounded, size: 16),
                                    label: Text('Reopen Ticket', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryRoyalNavy,
                                      side: const BorderSide(color: AppTheme.primaryRoyalNavy),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // Student Status Tracking Card (No Admin Action Buttons)
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              ticket.status == 'RESOLVED'
                                  ? Icons.verified_rounded
                                  : (ticket.status == 'IN_PROGRESS' ? Icons.engineering_rounded : Icons.hourglass_top_rounded),
                              size: 16,
                              color: ticket.status == 'RESOLVED' ? AppTheme.lowText : AppTheme.highText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Incident Lifecycle Tracker:',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const Spacer(),
                            _StatusBadge(status: ticket.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.status == 'RESOLVED'
                              ? 'This hazard has been resolved and safety closure verified by the campus facility engineering unit.'
                              : (ticket.status == 'IN_PROGRESS'
                                  ? 'A field technician has been dispatched and is currently resolving this issue on site.'
                                  : 'Your report has been analyzed by AI and prioritized in the university facility dispatch queue.'),
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // AI Summary Box
              if (ticket.aiSummary.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.mediumBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.mediumText.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.mediumText),
                          const SizedBox(width: 6),
                          Text(
                            'AI Triage Assessment',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.mediumText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticket.aiSummary,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Safety Advisory Box
              if (ticket.safetyAdvisory.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sevBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sevTextColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: sevTextColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.safetyAdvisory,
                          style: GoogleFonts.inter(color: sevTextColor, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'Incident Timeline',
                style: GoogleFonts.merriweather(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              ...ticket.timeline.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppTheme.primaryRoyalNavy, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.note,
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              DateFormat('h:mm a • MMM d').format(entry.timestamp),
                              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
