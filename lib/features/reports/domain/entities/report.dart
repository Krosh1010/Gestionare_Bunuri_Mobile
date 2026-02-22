import 'package:equatable/equatable.dart';

enum ReportType { byCategory, byStatus, byLocation }

class Report extends Equatable {
  final String id;
  final String title;
  final ReportType type;
  final DateTime generatedAt;
  final Map<String, dynamic> data;

  const Report({
    required this.id,
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.data,
  });

  @override
  List<Object?> get props => [id, title, type, generatedAt, data];
}

