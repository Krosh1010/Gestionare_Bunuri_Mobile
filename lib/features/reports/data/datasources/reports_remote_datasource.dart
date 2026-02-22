abstract class ReportsRemoteDataSource {
  Future<List<Map<String, dynamic>>> getReports();
  Future<Map<String, dynamic>> generateReport(String type);
  Future<void> exportReport(String reportId, String format);
}

