import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

abstract class ExportRemoteDataSource {
  Future<Uint8List> exportAssetsExcel({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  });

  Future<Uint8List> exportAssetsPdf({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  });

  Future<Uint8List> exportAssetsCsv({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  });
}

class ExportRemoteDataSourceImpl implements ExportRemoteDataSource {
  final ApiClient apiClient;

  ExportRemoteDataSourceImpl({required this.apiClient});

  Map<String, dynamic> _buildBody({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  }) {
    final body = <String, dynamic>{};
    if (categories != null && categories.isNotEmpty) {
      body['categories'] = categories;
    }
    if (warrantyStatus != null && warrantyStatus != 'all') {
      body['warrantyStatus'] = warrantyStatus;
    }
    if (insuranceStatus != null && insuranceStatus != 'all') {
      body['insuranceStatus'] = insuranceStatus;
    }
    if (columns != null && columns.isNotEmpty) {
      body['columns'] = columns;
    }
    return body;
  }

  Future<Uint8List> _downloadFile(String path, Map<String, dynamic> body) async {
    final response = await apiClient.dio.post(
      path,
      data: body,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': '*/*',
        },
      ),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  @override
  Future<Uint8List> exportAssetsExcel({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  }) async {
    final body = _buildBody(
      categories: categories,
      warrantyStatus: warrantyStatus,
      insuranceStatus: insuranceStatus,
      columns: columns,
    );
    return _downloadFile('/export/assets-excel', body);
  }

  @override
  Future<Uint8List> exportAssetsPdf({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  }) async {
    final body = _buildBody(
      categories: categories,
      warrantyStatus: warrantyStatus,
      insuranceStatus: insuranceStatus,
      columns: columns,
    );
    return _downloadFile('/export/assets-pdf', body);
  }

  @override
  Future<Uint8List> exportAssetsCsv({
    List<String>? categories,
    String? warrantyStatus,
    String? insuranceStatus,
    List<String>? columns,
  }) async {
    final body = _buildBody(
      categories: categories,
      warrantyStatus: warrantyStatus,
      insuranceStatus: insuranceStatus,
      columns: columns,
    );
    return _downloadFile('/export/assets-csv', body);
  }
}
