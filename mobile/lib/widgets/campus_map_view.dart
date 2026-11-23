import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class CampusBuildingData {
  final String id;
  final String name;
  final String code;
  final double lat;
  final double lng;
  final Offset mapPos; // Relative canvas position (0.0 - 1.0)
  final IconData icon;
  final String description;

  const CampusBuildingData({
    required this.id,
    required this.name,
    required this.code,
    required this.lat,
    required this.lng,
    required this.mapPos,
    required this.icon,
    required this.description,
  });
}

const List<CampusBuildingData> kPresidencyBuildings = [
  CampusBuildingData(
    id: 'block_a',
    name: 'Engineering Block A',
    code: 'BLK-A',
    lat: 13.1685,
    lng: 77.5350,
    mapPos: Offset(0.32, 0.38),
    icon: Icons.architecture_rounded,
    description: 'Main Engineering & Electronics Tech Labs',
  ),
  CampusBuildingData(
    id: 'block_b',
    name: 'Engineering Block B',
    code: 'BLK-B',
    lat: 13.1688,
    lng: 77.5358,
    mapPos: Offset(0.62, 0.32),
    icon: Icons.computer_rounded,
    description: 'Computer Science, AI & High-Performance Computing',
  ),
  CampusBuildingData(
    id: 'library',
    name: 'Central Library',
    code: 'LIB',
    lat: 13.1679,
    lng: 77.5348,
    mapPos: Offset(0.24, 0.54),
    icon: Icons.local_library_rounded,
    description: 'Knowledge Center, Digital Archives & Reading Lounges',
  ),
  CampusBuildingData(
    id: 'auditorium',
    name: 'Auditorium Complex',
    code: 'AUD',
    lat: 13.1672,
    lng: 77.5352,
    mapPos: Offset(0.48, 0.62),
    icon: Icons.theater_comedy_rounded,
    description: 'Main Amphitheater & Performing Arts Convention Hall',
  ),
  CampusBuildingData(
    id: 'management',
    name: 'School of Management',
    code: 'SOM',
    lat: 13.1692,
    lng: 77.5342,
    mapPos: Offset(0.18, 0.22),
    icon: Icons.business_center_rounded,
    description: 'Business School, Conference Suites & Seminar Halls',
  ),
  CampusBuildingData(
    id: 'hostel',
    name: 'Hostel Block',
    code: 'HSTL',
    lat: 13.1668,
    lng: 77.5365,
    mapPos: Offset(0.82, 0.74),
    icon: Icons.hotel_rounded,
    description: 'Student Residential Towers & On-Campus Infirmary',
  ),
  CampusBuildingData(
    id: 'admin',
    name: 'Admin Building',
    code: 'ADM',
    lat: 13.1680,
    lng: 77.5338,
    mapPos: Offset(0.12, 0.40),
    icon: Icons.account_balance_rounded,
    description: 'Registrar, University Governance & Command Desk',
  ),
  CampusBuildingData(
    id: 'sports',
    name: 'Sports Complex',
    code: 'SPRT',
    lat: 13.1662,
    lng: 77.5345,
    mapPos: Offset(0.35, 0.82),
    icon: Icons.sports_tennis_rounded,
    description: 'Indoor Arena, Gymnasium, Courts & Athletics Grounds',
  ),
  CampusBuildingData(
    id: 'cafeteria',
    name: 'Cafeteria',
    code: 'CAFE',
    lat: 13.1675,
    lng: 77.5360,
    mapPos: Offset(0.72, 0.52),
    icon: Icons.restaurant_rounded,
    description: 'University Dining Commons, Food Court & Kiosks',
  ),
  CampusBuildingData(
    id: 'gate',
    name: 'Main Security Gate',
    code: 'GATE',
    lat: 13.1695,
    lng: 77.5335,
    mapPos: Offset(0.08, 0.12),
    icon: Icons.security_rounded,
    description: 'Armed Security Checkpoint & Rapid Vehicle Access',
  ),
];

class CampusMapView extends StatefulWidget {
  final String selectedBuilding;
  final ValueChanged<CampusBuildingData> onBuildingSelected;
  final Map<String, int>? buildingIncidentCounts;

  const CampusMapView({
    super.key,
    required this.selectedBuilding,
    required this.onBuildingSelected,
    this.buildingIncidentCounts,
  });

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  bool _isSatellite = false;

  @override
  Widget build(BuildContext context) {
    final selectedData = kPresidencyBuildings.firstWhere(
      (b) => b.name == widget.selectedBuilding,
      orElse: () => kPresidencyBuildings[0],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.purePorcelain,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Map Modes & Coordinates HUD (Wrapped with Expanded to prevent 36px overflow)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded, color: AppTheme.primaryRoyalNavy, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Presidency University Campus',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Tap any block to pinpoint hazard GPS location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isSatellite = !_isSatellite);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isSatellite ? AppTheme.primaryRoyalNavy : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSatellite ? Icons.satellite_alt_rounded : Icons.map_rounded,
                          size: 13,
                          color: _isSatellite ? Colors.white : AppTheme.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSatellite ? 'Satellite' : 'Schematic',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isSatellite ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Canvas Map View
          // LayoutBuilder wraps Stack so Stack is the direct parent of Positioned!
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 240,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _isSatellite ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapW = constraints.maxWidth;
                  final mapH = constraints.maxHeight;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Custom Canvas Campus Schematic / Grid Background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CampusSchematicPainter(isSatellite: _isSatellite),
                        ),
                      ),

                      // Building Nodes on Canvas - DIRECT CHILDREN OF STACK!
                      ...kPresidencyBuildings.map((building) {
                        final isSelected = building.name == widget.selectedBuilding;
                        final activeIncidents = widget.buildingIncidentCounts?[building.name] ?? 0;

                        final left = (building.mapPos.dx * (mapW - 54)).clamp(6.0, mapW - 56.0);
                        final top = (building.mapPos.dy * (mapH - 54)).clamp(6.0, mapH - 56.0);

                        return Positioned(
                          left: left,
                          top: top,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onBuildingSelected(building);
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Marker Pin
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryRoyalNavy
                                              : (activeIncidents > 0 ? AppTheme.highBg : AppTheme.purePorcelain),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.secondaryRoyalGold
                                                : (activeIncidents > 0 ? AppTheme.highText : AppTheme.cardBorder),
                                            width: isSelected ? 2.5 : 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isSelected ? AppTheme.primaryRoyalNavy : Colors.black)
                                                  .withValues(alpha: isSelected ? 0.3 : 0.1),
                                              blurRadius: isSelected ? 8 : 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          building.icon,
                                          size: 15,
                                          color: isSelected
                                              ? AppTheme.secondaryRoyalGold
                                              : (activeIncidents > 0 ? AppTheme.highText : AppTheme.primaryRoyalNavy),
                                        ),
                                      ),
                                      if (activeIncidents > 0)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.criticalText,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$activeIncidents',
                                              style: GoogleFonts.inter(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Marker Label
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryRoyalNavy
                                          : AppTheme.purePorcelain.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.secondaryRoyalGold : AppTheme.cardBorder,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      building.code,
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Compass & Scale Pill
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.purePorcelain.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.north_rounded, size: 10, color: AppTheme.primaryRoyalNavy),
                              const SizedBox(width: 2),
                              Text(
                                'North • 1:500m',
                                style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Selected Building Details Card (All Text wrapped in Expanded / Ellipsis)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mediumBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRoyalNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(selectedData.icon, color: AppTheme.secondaryRoyalGold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedData.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryRoyalNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedData.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Geotag: ${selectedData.lat.toStringAsFixed(4)}° N, ${selectedData.lng.toStringAsFixed(4)}° E',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryRoyalGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lowBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.lowText.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'PINNED',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.lowText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusSchematicPainter extends CustomPainter {
  final bool isSatellite;

  _CampusSchematicPainter({required this.isSatellite});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green Lawns
    final lawnPaint = Paint()
      ..color = isSatellite ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFE8F5E9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.45), const Radius.circular(16)),
      lawnPaint,
    );

    // Roads & Pedestrian Paths
    final roadPaint = Paint()
      ..color = isSatellite ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Main Spine Avenue
    path.moveTo(size.width * 0.05, size.height * 0.15);
    path.lineTo(size.width * 0.35, size.height * 0.45);
    path.lineTo(size.width * 0.75, size.height * 0.45);
    path.lineTo(size.width * 0.90, size.height * 0.85);

    // Cross Pathway to Library & Sports
    path.moveTo(size.width * 0.35, size.height * 0.45);
    path.lineTo(size.width * 0.25, size.height * 0.85);

    canvas.drawPath(path, roadPaint);

    // Fine Walkways
    final walkPaint = Paint()
      ..color = isSatellite ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final walkPath = Path();
    walkPath.moveTo(size.width * 0.25, size.height * 0.25);
    walkPath.lineTo(size.width * 0.70, size.height * 0.25);
    walkPath.lineTo(size.width * 0.70, size.height * 0.70);
    walkPath.lineTo(size.width * 0.25, size.height * 0.70);
    walkPath.close();

    canvas.drawPath(walkPath, walkPaint);
  }

  @override
  bool shouldRepaint(covariant _CampusSchematicPainter oldDelegate) =>
      oldDelegate.isSatellite != isSatellite;
}
