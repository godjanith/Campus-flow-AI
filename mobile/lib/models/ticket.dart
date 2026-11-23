class Ticket {
  final String id;
  final String ticketCode;
  final String title;
  final String description;
  final String building;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String category;
  final String severity;
  final String aiSummary;
  final String estimatedResolutionTime;
  final String safetyAdvisory;
  final String triageEngineUsed;
  final String status;
  final String reporterName;
  final String reporterRegNo;
  final List<TimelineEntry> timeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.ticketCode,
    required this.title,
    required this.description,
    required this.building,
    required this.lat,
    required this.lng,
    this.imageUrl,
    required this.category,
    required this.severity,
    required this.aiSummary,
    required this.estimatedResolutionTime,
    required this.safetyAdvisory,
    required this.triageEngineUsed,
    required this.status,
    required this.reporterName,
    required this.reporterRegNo,
    required this.timeline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final reporter = json['reportedBy'] as Map<String, dynamic>? ?? {};
    final timelineList = (json['timeline'] as List<dynamic>? ?? [])
        .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return Ticket(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      ticketCode: json['ticketCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      building: json['building'] as String? ?? 'Unknown',
      lat: (location['lat'] as num?)?.toDouble() ?? 13.1718,
      lng: (location['lng'] as num?)?.toDouble() ?? 77.5361,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? 'Civil & Structural',
      severity: json['severity'] as String? ?? 'MEDIUM',
      aiSummary: json['aiSummary'] as String? ?? '',
      estimatedResolutionTime: json['estimatedResolutionTime'] as String? ?? '2 hours',
      safetyAdvisory: json['safetyAdvisory'] as String? ?? '',
      triageEngineUsed: json['triageEngineUsed'] as String? ?? 'OFFLINE_NLP_HEURISTIC',
      status: json['status'] as String? ?? 'OPEN',
      reporterName: reporter['name'] as String? ?? 'Campus Student',
      reporterRegNo: reporter['regNo'] as String? ?? '',
      timeline: timelineList,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TimelineEntry {
  final String status;
  final String note;
  final DateTime timestamp;

  TimelineEntry({
    required this.status,
    required this.note,
    required this.timestamp,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      status: json['status'] as String? ?? 'OPEN',
      note: json['note'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
