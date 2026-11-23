import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/ticket.dart';

class TriageResultSheet extends StatelessWidget {
  final Ticket ticket;

  const TriageResultSheet({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final sevTextColor = AppTheme.severityColor(ticket.severity);
    final sevBgColor = AppTheme.severityBgColor(ticket.severity);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
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
          padding: const EdgeInsets.all(22),
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

              // Institutional Check Crest
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRoyalNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondaryRoyalGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: AppTheme.secondaryRoyalGold, size: 36),
              ),
              const SizedBox(height: 14),

              Text(
                'Incident Triaged & Dispatched',
                style: GoogleFonts.merriweather(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.ticketCode,
                style: GoogleFonts.robotoMono(
                  color: AppTheme.primaryRoyalNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),

              // Key Badges Grid
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'SEVERITY RATING',
                      value: ticket.severity,
                      color: sevTextColor,
                      bgColor: sevBgColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      label: 'CREW ETA',
                      value: ticket.estimatedResolutionTime,
                      color: AppTheme.primaryRoyalNavy,
                      bgColor: AppTheme.mediumBg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'LOCATION',
                      value: ticket.building,
                      color: AppTheme.textPrimary,
                      bgColor: AppTheme.surfaceLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      label: 'TRIAGE ENGINE',
                      value: ticket.triageEngineUsed.contains('GEMINI') ? 'Gemini 1.5 Pro' : 'Heuristic NLP',
                      color: AppTheme.primaryRoyalNavy,
                      bgColor: AppTheme.surfaceLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // AI Summary Box
              Container(
                width: double.infinity,
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
                          style: GoogleFonts.inter(color: AppTheme.mediumText, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.aiSummary,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Safety Advisory Box
              if (ticket.safetyAdvisory.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sevBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sevTextColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_rounded, color: sevTextColor, size: 18),
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
              const SizedBox(height: 20),

              // Return to Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRoyalNavy,
                    foregroundColor: AppTheme.purePorcelain,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Return to Live Dashboard',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
