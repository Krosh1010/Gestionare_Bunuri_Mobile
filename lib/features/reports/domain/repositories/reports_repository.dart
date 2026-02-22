import '../entities/report.dart';

abstract class ReportsRepository {
  Future<List<Report>> getReports();
  Future<Report> generateReport(ReportType type);
  Future<void> exportReport(String reportId, String format);
}

