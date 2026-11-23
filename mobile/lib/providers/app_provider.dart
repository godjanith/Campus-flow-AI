import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/offline_queue.dart';

class AppProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  bool _isOnline = true;
  Map<String, dynamic>? _user;
  final SocketService _socketService = SocketService();

  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  Map<String, dynamic>? get user => _user;
  bool get isSocketConnected => _socketService.isConnected;

  AppProvider() {
    _monitorConnectivity();
    _setupSocketListeners();
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
      if (_isOnline && wasOffline) {
        _syncOfflineQueue();
      }
    });
  }

  void _setupSocketListeners() {
    _socketService.onTicketCreated((ticket) {
      if (!_tickets.any((t) => t.id == ticket.id)) {
        _tickets.insert(0, ticket);
        notifyListeners();
      }
    });

    _socketService.onTicketUpdated((updated) {
      final idx = _tickets.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        _tickets[idx] = updated;
        notifyListeners();
      }
    });

    _socketService.onTicketDeleted((id) {
      _tickets.removeWhere((t) => t.id == id);
      notifyListeners();
    });
  }

  Future<void> setUser(Map<String, dynamic> userData) async {
    _user = userData;
    final regNo = userData['regNo'] as String?;
    if (regNo != null) {
      _socketService.joinStudentRoom(regNo);
    }
    notifyListeners();
  }

  Future<void> loadTickets() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tickets = await ApiService.getTickets();
    } catch (e) {
      debugPrint('Failed to load tickets: $e');
      if (_tickets.isEmpty) {
        _tickets = _getDemoTickets();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Ticket> _getDemoTickets() {
    final now = DateTime.now();
    return [
      Ticket(
        id: 'demo_1',
        ticketCode: 'CF-849201',
        title: 'Exposed High-Voltage Conduit Sparking',
        description: 'Corridor junction box near Lab 304 emitting sparks and ozone smell.',
        building: 'Engineering Block A',
        lat: 13.1723,
        lng: 77.5366,
        category: 'Electrical Safety',
        severity: 'CRITICAL',
        aiSummary: '[CRITICAL] Active electrical arcing hazard detected near Lab 304.',
        estimatedResolutionTime: '20 mins',
        safetyAdvisory: 'DANGER: Evacuate 10-meter radius immediately. Do not touch metal doorframe.',
        triageEngineUsed: 'GEMINI_MULTIMODAL',
        status: 'OPEN',
        reporterName: 'Janith V C',
        reporterRegNo: '20252MCA0318',
        timeline: [
          TimelineEntry(
            status: 'OPEN',
            note: 'Incident reported & triaged as CRITICAL by CampusFlow AI.',
            timestamp: now.subtract(const Duration(minutes: 15)),
          ),
        ],
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
      ),
      Ticket(
        id: 'demo_2',
        ticketCode: 'CF-392014',
        title: 'Chilled Water Pipe Leak Flooding Lobby',
        description: 'Overhead HVAC chilled water line leaking onto granite tiles.',
        building: 'Auditorium Complex',
        lat: 13.1712,
        lng: 77.5355,
        category: 'Plumbing & Water',
        severity: 'HIGH',
        aiSummary: '[HIGH] Chilled water line rupture causing severe slip hazard.',
        estimatedResolutionTime: '45 mins',
        safetyAdvisory: 'Caution: Wet granite flooring. Use West Wing entrance.',
        triageEngineUsed: 'GEMINI_MULTIMODAL',
        status: 'IN_PROGRESS',
        reporterName: 'Janith V C',
        reporterRegNo: '20252MCA0318',
        timeline: [
          TimelineEntry(
            status: 'IN_PROGRESS',
            note: 'Plumbing crew dispatched with water containment unit.',
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
          TimelineEntry(
            status: 'OPEN',
            note: 'Automated triage completed.',
            timestamp: now.subtract(const Duration(minutes: 35)),
          ),
        ],
        createdAt: now.subtract(const Duration(minutes: 35)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ),
      Ticket(
        id: 'demo_3',
        ticketCode: 'CF-119384',
        title: 'Wi-Fi Access Point Offline in Lab 202',
        description: 'Lab 202 primary AP is unresponsive; students cannot access internal portals.',
        building: 'Engineering Block B',
        lat: 13.1718,
        lng: 77.5361,
        category: 'IT & Network',
        severity: 'MEDIUM',
        aiSummary: '[MEDIUM] Network node degradation affecting student workstations.',
        estimatedResolutionTime: '1 hour',
        safetyAdvisory: 'No physical hazard. Use 5GHz backup SSID if required.',
        triageEngineUsed: 'OFFLINE_NLP_HEURISTIC',
        status: 'RESOLVED',
        reporterName: 'Rahul R',
        reporterRegNo: '20252MCA0301',
        timeline: [
          TimelineEntry(
            status: 'RESOLVED',
            note: 'Switch port power-cycled. Access point fully operational.',
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  Future<void> syncOfflineQueueNow() async {
    await _syncOfflineQueue();
  }

  Future<void> updateTicketStatus(String ticketId, String newStatus, {String? note}) async {
    try {
      final updated = await ApiService.updateTicketStatus(ticketId, newStatus, note: note);
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _tickets[idx] = updated;
        notifyListeners();
      }
    } catch (_) {
      // Local fallback for offline / demo mode
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        final current = _tickets[idx];
        final now = DateTime.now();
        final updatedTimeline = List<TimelineEntry>.from(current.timeline)
          ..add(TimelineEntry(
            status: newStatus,
            note: note ?? (newStatus == 'RESOLVED' ? 'Issue verified resolved by technician.' : 'Crew dispatched to location.'),
            timestamp: now,
          ));
        _tickets[idx] = Ticket(
          id: current.id,
          ticketCode: current.ticketCode,
          title: current.title,
          description: current.description,
          building: current.building,
          lat: current.lat,
          lng: current.lng,
          imageUrl: current.imageUrl,
          category: current.category,
          severity: current.severity,
          aiSummary: current.aiSummary,
          estimatedResolutionTime: newStatus == 'RESOLVED' ? 'Resolved' : current.estimatedResolutionTime,
          safetyAdvisory: current.safetyAdvisory,
          triageEngineUsed: current.triageEngineUsed,
          status: newStatus,
          reporterName: current.reporterName,
          reporterRegNo: current.reporterRegNo,
          timeline: updatedTimeline,
          createdAt: current.createdAt,
          updatedAt: now,
        );
        notifyListeners();
      }
    }
  }

  Future<void> _syncOfflineQueue() async {
    final queue = await OfflineQueue.getQueue();
    if (queue.isEmpty) return;

    for (final report in queue) {
      try {
        await ApiService.createTicket(
          title: report['title'] as String,
          description: report['description'] as String,
          building: report['building'] as String?,
        );
      } catch (e) {
        debugPrint('Offline sync failed for: ${report['title']}');
        return;
      }
    }
    await OfflineQueue.clearQueue();
    await loadTickets();
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _tickets = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
