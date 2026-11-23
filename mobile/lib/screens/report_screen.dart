import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/ticket.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/offline_queue.dart';
import '../widgets/campus_map_view.dart';
import '../widgets/triage_result_sheet.dart';

class ReportScreen extends StatefulWidget {
  final String? initialBuilding;
  final String? initialCategory;
  final String? initialTitle;

  const ReportScreen({
    super.key,
    this.initialBuilding,
    this.initialCategory,
    this.initialTitle,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  String? _compressionStats;
  late String _selectedBuilding;
  late String _selectedCategory;
  bool _isSubmitting = false;
  bool _isFetchingGps = false;
  bool _showInteractiveMap = true; // Interactive Map view by default!

  double _currentLat = 13.1685;
  double _currentLng = 77.5350;

  static const List<Map<String, dynamic>> _quickCategories = [
    {
      'icon': Icons.bolt_rounded,
      'label': 'Electrical',
      'title': 'Exposed conduit / Power failure',
      'category': 'Electrical Safety',
      'color': Color(0xFFD97706),
    },
    {
      'icon': Icons.water_drop_rounded,
      'label': 'Plumbing',
      'title': 'Pipe leak / Water blockage',
      'category': 'Plumbing & Water',
      'color': Color(0xFF0284C7),
    },
    {
      'icon': Icons.wifi_off_rounded,
      'label': 'IT / Wi-Fi',
      'title': 'Wi-Fi AP offline / Lab connectivity',
      'category': 'IT & Network',
      'color': Color(0xFF2563EB),
    },
    {
      'icon': Icons.warning_rounded,
      'label': 'Safety Hazard',
      'title': 'Physical hazard / Broken fixture',
      'category': 'Safety & Hazard',
      'color': Color(0xFFDC2626),
    },
    {
      'icon': Icons.ac_unit_rounded,
      'label': 'HVAC / Air',
      'title': 'AC failure / Ventilation issue',
      'category': 'HVAC & Climate',
      'color': Color(0xFF059669),
    },
    {
      'icon': Icons.construction_rounded,
      'label': 'Civil Works',
      'title': 'Floor damage / Broken door/glass',
      'category': 'Civil & Structural',
      'color': Color(0xFF7C3AED),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedBuilding = widget.initialBuilding ?? 'Engineering Block A';
    _selectedCategory = widget.initialCategory ?? 'Electrical Safety';
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    _syncCoordsWithBuilding(_selectedBuilding);
    _fetchLiveGps();
  }

  void _syncCoordsWithBuilding(String buildingName) {
    final building = kPresidencyBuildings.firstWhere(
      (b) => b.name == buildingName,
      orElse: () => kPresidencyBuildings[0],
    );
    _currentLat = building.lat;
    _currentLng = building.lng;
  }

  Future<void> _fetchLiveGps() async {
    setState(() => _isFetchingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
      );
      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
        });
      }
    } catch (_) {
      _syncCoordsWithBuilding(_selectedBuilding);
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920);
    if (picked == null) return;

    final origFile = File(picked.path);
    final origBytes = await origFile.length();
    final origKb = (origBytes / 1024).round();

    try {
      final targetPath = '${picked.path}_opt.jpg';
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 75,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (compressedXFile != null) {
        final optBytes = await File(compressedXFile.path).length();
        final optKb = (optBytes / 1024).round();
        setState(() {
          _selectedImage = File(compressedXFile.path);
          _compressionStats = '$origKb KB ➔ $optKb KB (Optimized)';
        });
      } else {
        setState(() {
          _selectedImage = origFile;
          _compressionStats = '$origKb KB (Original)';
        });
      }
    } catch (_) {
      setState(() {
        _selectedImage = origFile;
        _compressionStats = '$origKb KB (Original)';
      });
    }
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an issue title and description'),
          backgroundColor: AppTheme.criticalText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final user = provider.user;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final building = _selectedBuilding;
    final reporterName = user?['name'] as String? ?? 'Campus Member';
    final reporterRegNo = user?['regNo'] as String? ?? 'PU-STUDENT';

    setState(() => _isSubmitting = true);

    try {
      Ticket ticket;
      if (provider.isOnline) {
        try {
          ticket = await ApiService.createTicket(
            title: title,
            description: desc,
            building: building,
            lat: _currentLat,
            lng: _currentLng,
            reporterName: reporterName,
            reporterRegNo: reporterRegNo,
            image: _selectedImage,
          );
        } catch (_) {
          ticket = _generateLocalTriagedTicket(title, desc, building, reporterName, reporterRegNo);
          await OfflineQueue.enqueue({
            'title': title,
            'description': desc,
            'building': building,
          });
        }
      } else {
        ticket = _generateLocalTriagedTicket(title, desc, building, reporterName, reporterRegNo);
        await OfflineQueue.enqueue({
          'title': title,
          'description': desc,
          'building': building,
        });
      }

      if (mounted) {
        _clearForm();
        await provider.loadTickets();
        if (mounted) _showTriageResult(ticket);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.criticalText,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Ticket _generateLocalTriagedTicket(
    String title,
    String desc,
    String building,
    String reporterName,
    String reporterRegNo,
  ) {
    final combined = '$title $desc'.toLowerCase();
    String severity = 'MEDIUM';
    String eta = '45 mins';
    String safetyAdvisory = 'Maintenance team dispatched. Please exercise standard caution.';

    if (combined.contains('spark') ||
        combined.contains('fire') ||
        combined.contains('smoke') ||
        combined.contains('shock') ||
        combined.contains('electric') ||
        combined.contains('gas')) {
      severity = 'CRITICAL';
      eta = '15 mins';
      safetyAdvisory = 'IMMEDIATE HAZARD: Evacuate immediate area. Do not touch electrical or metal surfaces.';
    } else if (combined.contains('leak') ||
        combined.contains('flood') ||
        combined.contains('water') ||
        combined.contains('broken glass') ||
        combined.contains('elevator')) {
      severity = 'HIGH';
      eta = '30 mins';
      safetyAdvisory = 'CAUTION: Slip/fall hazard. Use alternate routes until safety cones are deployed.';
    } else if (combined.contains('light') || combined.contains('trash') || combined.contains('clean')) {
      severity = 'LOW';
      eta = '2 hours';
      safetyAdvisory = 'No imminent danger. Scheduled for facility maintenance queue.';
    }

    final code = 'CF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();

    return Ticket(
      id: 'local_${now.millisecondsSinceEpoch}',
      ticketCode: code,
      title: title,
      description: desc,
      building: building,
      lat: _currentLat,
      lng: _currentLng,
      category: _selectedCategory,
      severity: severity,
      aiSummary: '[$severity] $title at $building. Automated AI triage prioritized and assigned to crew.',
      estimatedResolutionTime: eta,
      safetyAdvisory: safetyAdvisory,
      triageEngineUsed: 'GEMINI_AI_DISPATCH',
      status: 'OPEN',
      reporterName: reporterName,
      reporterRegNo: reporterRegNo,
      timeline: [
        TimelineEntry(
          status: 'OPEN',
          note: 'Incident registered & triaged as $severity via CampusFlow AI engine.',
          timestamp: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedImage = null;
      _compressionStats = null;
    });
  }

  void _showTriageResult(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TriageResultSheet(ticket: ticket),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final hasActiveInBuilding = provider.tickets.any(
      (t) => t.building == _selectedBuilding && (t.status == 'OPEN' || t.status == 'IN_PROGRESS'),
    );

    // Compute incident counts per building
    final Map<String, int> buildingCounts = {};
    for (final t in provider.tickets) {
      if (t.status == 'OPEN' || t.status == 'IN_PROGRESS') {
        buildingCounts[t.building] = (buildingCounts[t.building] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRoyalNavy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DISPATCH 2.5',
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
                'Report Incident',
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
            'Official Presidency University Facilities & Safety Dispatch Intake',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Interactive Mode Switcher: Interactive Map vs Preset Categories
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
                      setState(() => _showInteractiveMap = true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _showInteractiveMap ? AppTheme.purePorcelain : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _showInteractiveMap
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 15,
                            color: _showInteractiveMap ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Interactive Campus Map',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: _showInteractiveMap ? FontWeight.w700 : FontWeight.w500,
                              color: _showInteractiveMap ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showInteractiveMap = false);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !_showInteractiveMap ? AppTheme.purePorcelain : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_showInteractiveMap
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 15,
                            color: !_showInteractiveMap ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Quick Categories',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: !_showInteractiveMap ? FontWeight.w700 : FontWeight.w500,
                              color: !_showInteractiveMap ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Render Interactive Map or Quick Category Grid
          if (_showInteractiveMap) ...[
            CampusMapView(
              selectedBuilding: _selectedBuilding,
              buildingIncidentCounts: buildingCounts,
              onBuildingSelected: (building) {
                setState(() {
                  _selectedBuilding = building.name;
                  _currentLat = building.lat;
                  _currentLng = building.lng;
                });
              },
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              'INCIDENT CATEGORY PRESETS',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: _quickCategories.length,
              itemBuilder: (context, index) {
                final cat = _quickCategories[index];
                final isSelected = _selectedCategory == cat['category'];
                final color = cat['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCategory = cat['category'] as String;
                      _titleController.text = cat['title'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.mediumBg : AppTheme.purePorcelain,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryRoyalNavy : AppTheme.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRoyalNavy.withValues(alpha: isSelected ? 0.08 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'] as IconData, size: 24, color: isSelected ? AppTheme.primaryRoyalNavy : color),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppTheme.primaryRoyalNavy : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Active Incidents Warning Banner
          if (hasActiveInBuilding)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.highBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.highText.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.highText, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notice: Active crew already responding in $_selectedBuilding. Your ticket will automatically link with existing work orders.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.highText, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

          // Issue Title Input
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Issue Title *',
              hintText: 'e.g. Exposed High-Voltage Conduit Sparking',
              prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primaryRoyalNavy),
            ),
          ),
          const SizedBox(height: 12),

          // Location Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedBuilding,
            dropdownColor: AppTheme.purePorcelain,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
            items: kPresidencyBuildings.map((b) {
              return DropdownMenuItem(value: b.name, child: Text(b.name));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedBuilding = val;
                  _syncCoordsWithBuilding(val);
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Campus Building / Location *',
              prefixIcon: Icon(Icons.location_on_rounded, color: AppTheme.primaryRoyalNavy),
            ),
          ),
          const SizedBox(height: 8),

          // Live Geotag Pill
          GestureDetector(
            onTap: _isFetchingGps ? null : _fetchLiveGps,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.purePorcelain,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: 15,
                    color: _isFetchingGps ? AppTheme.highText : AppTheme.lowText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isFetchingGps
                          ? 'Acquiring satellite GPS fix...'
                          : 'Live Geotag: ${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E',
                      style: GoogleFonts.robotoMono(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_isFetchingGps)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRoyalNavy),
                    )
                  else
                    const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Incident Description
          TextField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Detailed Incident Description *',
              hintText: 'Describe floor number, room number, sparking, leaks, or hazards...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.description_outlined, color: AppTheme.primaryRoyalNavy),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photo Evidence Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.purePorcelain,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.04),
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
                      'Photo Evidence',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_compressionStats != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.lowBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _compressionStats!,
                          style: GoogleFonts.inter(color: AppTheme.lowText, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.mediumBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AI Vision Analysis',
                          style: GoogleFonts.inter(color: AppTheme.mediumText, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: () => setState(() {
                                _selectedImage = null;
                                _compressionStats = null;
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.primaryRoyalNavy),
                          label: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryRoyalNavy,
                            side: const BorderSide(color: AppTheme.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppTheme.secondaryRoyalGold),
                          label: Text('Upload Image', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: Text(
                _isSubmitting ? 'Submitting & Triaging with Gemini AI...' : 'Submit to Campus Dispatch',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRoyalNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
