import '../../domain/entities/report.dart';

class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.title,
    required super.type,
    required super.generatedAt,
    required super.data,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.byCategory,
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      data: json['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'generatedAt': generatedAt.toIso8601String(),
      'data': data,
    };
  }
}

