import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/offline_queue.dart';

class AppProvider extends ChangeNotifier {
  static const String _localTicketsKey = 'campusflow_local_tickets_cache';

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
    _initLocalState();
    _monitorConnectivity();
    _setupSocketListeners();
  }

  Future<void> _initLocalState() async {
    _tickets = await _loadLocalTickets();
    await _recoverPendingQueueTickets();
    notifyListeners();
    // Then attempt server sync in background
    loadTickets();
  }

  Future<void> _saveLocalTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _tickets.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_localTicketsKey, list);
    } catch (e) {
      debugPrint('Failed to save local tickets: $e');
    }
  }

  Future<List<Ticket>> _loadLocalTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_localTicketsKey) ?? [];
      return raw.map((e) => Ticket.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Failed to load local tickets: $e');
      return [];
    }
  }

  Future<void> _recoverPendingQueueTickets() async {
    try {
      final queue = await OfflineQueue.getQueue();
      if (queue.isEmpty) return;

      bool modified = false;
      for (final q in queue) {
        final title = q['title'] as String? ?? 'Campus Incident';
        final code = q['ticketCode'] as String? ?? '';
        final alreadyPresent = _tickets.any((t) =>
            (code.isNotEmpty && t.ticketCode == code) ||
            t.title == title);

        if (!alreadyPresent) {
          final now = DateTime.now();
          final ticketCode = code.isNotEmpty
              ? code
              : 'CF-${now.millisecondsSinceEpoch.toString().substring(7)}';

          final recoveredTicket = Ticket(
            id: 'offline_${now.millisecondsSinceEpoch}_${title.hashCode}',
            ticketCode: ticketCode,
            title: title,
            description: q['description'] as String? ?? '',
            building: q['building'] as String? ?? 'Engineering Block A',
            lat: (q['lat'] as num?)?.toDouble() ?? 13.1685,
            lng: (q['lng'] as num?)?.toDouble() ?? 77.5350,
            imageUrl: null,
            category: q['category'] as String? ?? 'Civil & Structural',
            severity: q['severity'] as String? ?? 'HIGH',
            aiSummary: '[OFFLINE QUEUE] $title at ${q['building'] ?? 'campus'}. Queued for cloud sync.',
            estimatedResolutionTime: 'Pending Sync',
            safetyAdvisory: 'Offline report registered. Stored in local incident ledger.',
            triageEngineUsed: 'OFFLINE_INCIDENT_QUEUE',
            status: 'OPEN',
            reporterName: (q['reporterName'] as String?) ?? (_user?['name'] as String? ?? 'Campus Member'),
            reporterRegNo: (q['reporterRegNo'] as String?) ?? (_user?['regNo'] as String? ?? 'PU-STUDENT'),
            timeline: [
              TimelineEntry(
                status: 'OPEN',
                note: 'Saved in offline incident queue. Will sync automatically upon server connection.',
                timestamp: now,
              ),
            ],
            createdAt: now,
            updatedAt: now,
          );

          _tickets.insert(0, recoveredTicket);
          modified = true;
        }
      }

      if (modified) {
        await _saveLocalTickets();
      }
    } catch (e) {
      debugPrint('Error recovering queue tickets: $e');
    }
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
      if (!_tickets.any((t) => t.id == ticket.id || (t.ticketCode.isNotEmpty && t.ticketCode == ticket.ticketCode))) {
        _tickets.insert(0, ticket);
        _saveLocalTickets();
        notifyListeners();
      }
    });

    _socketService.onTicketUpdated((updated) {
      final idx = _tickets.indexWhere((t) => t.id == updated.id || (t.ticketCode.isNotEmpty && t.ticketCode == updated.ticketCode));
      if (idx != -1) {
        _tickets[idx] = updated;
        _saveLocalTickets();
        notifyListeners();
      }
    });

    _socketService.onTicketDeleted((id) {
      _tickets.removeWhere((t) => t.id == id);
      _saveLocalTickets();
      notifyListeners();
    });

    _socketService.onTicketsCleared(() {
      _tickets.clear();
      _saveLocalTickets();
      notifyListeners();
    });
  }

  Future<void> setUser(Map<String, dynamic> userData) async {
    _user = userData;
    final regNo = userData['regNo'] as String?;
    if (regNo != null) {
      _socketService.joinStudentRoom(regNo);
    }
    // Re-verify local tickets for this user
    await _recoverPendingQueueTickets();
    notifyListeners();
  }

  Future<void> addTicket(Ticket ticket) async {
    final alreadyExists = _tickets.any((t) =>
        t.id == ticket.id ||
        (t.ticketCode.isNotEmpty && t.ticketCode == ticket.ticketCode));

    if (!alreadyExists) {
      _tickets.insert(0, ticket);
      await _saveLocalTickets();
      notifyListeners();
    }
  }

  Future<void> loadTickets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final serverTickets = await ApiService.getTickets();
      // Merge server tickets with any local offline tickets that haven't reached server yet
      final merged = List<Ticket>.from(serverTickets);
      for (final local in _tickets) {
        final onServer = merged.any((s) =>
            s.id == local.id ||
            (s.ticketCode.isNotEmpty && s.ticketCode == local.ticketCode) ||
            (s.title == local.title && s.building == local.building));
        if (!onServer) {
          merged.add(local);
        }
      }
      _tickets = merged;
      await _saveLocalTickets();
    } catch (e) {
      debugPrint('Failed to load tickets from server (using local state): $e');
      if (_tickets.isEmpty) {
        _tickets = await _loadLocalTickets();
      }
      await _recoverPendingQueueTickets();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncOfflineQueueNow() async {
    return await _syncOfflineQueue();
  }

  Future<void> purgeAllTickets() async {
    try {
      await ApiService.purgeAllTickets();
    } catch (e) {
      debugPrint('Purge tickets error: $e');
    }
    _tickets.clear();
    await _saveLocalTickets();
    await OfflineQueue.clearQueue();
    notifyListeners();
  }

  Future<void> updateTicketStatus(String ticketId, String newStatus, {String? note}) async {
    try {
      final updated = await ApiService.updateTicketStatus(ticketId, newStatus, note: note);
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _tickets[idx] = updated;
        await _saveLocalTickets();
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
        await _saveLocalTickets();
        notifyListeners();
      }
    }
  }

  Future<bool> _syncOfflineQueue() async {
    final queue = await OfflineQueue.getQueue();
    if (queue.isEmpty) return true;

    bool allSuccess = true;
    final remaining = <Map<String, dynamic>>[];

    for (final report in queue) {
      try {
        await ApiService.createTicket(
          title: report['title'] as String,
          description: report['description'] as String,
          building: report['building'] as String?,
          reporterName: report['reporterName'] as String?,
          reporterRegNo: report['reporterRegNo'] as String?,
        );
      } catch (e) {
        debugPrint('Offline sync failed for: ${report['title']}: $e');
        allSuccess = false;
        remaining.add(report);
      }
    }

    if (allSuccess) {
      await OfflineQueue.clearQueue();
      await loadTickets();
      return true;
    } else {
      // Save remaining unsynced items
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('campusflow_offline_queue', remaining.map((e) => jsonEncode(e)).toList());
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _tickets = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localTicketsKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
