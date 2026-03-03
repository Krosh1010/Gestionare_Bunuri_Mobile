import 'asset.dart';

class PagedAssetsResult {
  final List<Asset> items;
  final int totalCount;
  final double totalValue;

  const PagedAssetsResult({
    required this.items,
    required this.totalCount,
    required this.totalValue,
  });
}

