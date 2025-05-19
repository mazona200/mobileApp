import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  pending,
  inProgress,
  resolved,
  rejected
}

enum ReportPriority {
  low,
  medium,
  high,
  emergency
}

class Report {
  final String id;
  final String title;
  final String description;
  final String category;
  final ReportPriority priority;
  final ReportStatus status;
  final String reportedBy;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<String> imageUrls;
  final Map<String, dynamic> location;
  final String? assignedTo;
  final String? resolutionNotes;
  final List<ReportUpdate> updates;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.status = ReportStatus.pending,
    required this.reportedBy,
    required this.createdAt,
    this.resolvedAt,
    this.imageUrls = const [],
    required this.location,
    this.assignedTo,
    this.resolutionNotes,
    this.updates = const [],
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      priority: ReportPriority.values.firstWhere(
        (e) => e.toString() == 'ReportPriority.${data['priority']}',
        orElse: () => ReportPriority.medium,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${data['status']}',
        orElse: () => ReportStatus.pending,
      ),
      reportedBy: data['reportedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: Map<String, dynamic>.from(data['location'] ?? {}),
      assignedTo: data['assignedTo'],
      resolutionNotes: data['resolutionNotes'],
      updates: (data['updates'] as List<dynamic>? ?? [])
          .map((update) => ReportUpdate.fromMap(update))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'reportedBy': reportedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'imageUrls': imageUrls,
      'location': location,
      'assignedTo': assignedTo,
      'resolutionNotes': resolutionNotes,
      'updates': updates.map((update) => update.toMap()).toList(),
    };
  }
}

class ReportUpdate {
  final String id;
  final String content;
  final String updatedBy;
  final DateTime updatedAt;
  final ReportStatus? newStatus;
  final String? assignedTo;

  ReportUpdate({
    required this.id,
    required this.content,
    required this.updatedBy,
    required this.updatedAt,
    this.newStatus,
    this.assignedTo,
  });

  factory ReportUpdate.fromMap(Map<String, dynamic> map) {
    return ReportUpdate(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      newStatus: map['newStatus'] != null
          ? ReportStatus.values.firstWhere(
              (e) => e.toString() == 'ReportStatus.${map['newStatus']}',
              orElse: () => ReportStatus.pending,
            )
          : null,
      assignedTo: map['assignedTo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'newStatus': newStatus?.toString().split('.').last,
      'assignedTo': assignedTo,
    };
  }
} 