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
      _tickets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
