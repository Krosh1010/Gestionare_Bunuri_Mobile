import 'dart:typed_data';
import '../datasources/export_remote_datasource.dart';

class ExportRepository {
  final ExportRemoteDataSource remoteDataSource;

  ExportRepository({required this.remoteDataSource});

  Future<Uint8List> exportAssets({
    required String format,
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  }) async {
    switch (format) {
      case 'excel':
        return remoteDataSource.exportAssetsExcel(
          categories: categories,
          warrantyStatus: warrantyStatus,
          insuranceStatus: insuranceStatus,
          columns: columns,
        );
      case 'pdf':
        return remoteDataSource.exportAssetsPdf(
          categories: categories,
          warrantyStatus: warrantyStatus,
          insuranceStatus: insuranceStatus,
          columns: columns,
        );
      case 'csv':
        return remoteDataSource.exportAssetsCsv(
          categories: categories,
          warrantyStatus: warrantyStatus,
          insuranceStatus: insuranceStatus,
          columns: columns,
        );
      default:
        throw ArgumentError('Format necunoscut: $format');
    }
  }
}

