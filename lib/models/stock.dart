/// Resposta GET /stock/total-value (ou equivalente)
class TotalValueResponse {
  TotalValueResponse({
    required this.totalValue,
    required this.totalProducts,
    required this.productsWithStock,
  });

  factory TotalValueResponse.fromJson(Map<String, dynamic> json) {
    return TotalValueResponse(
      totalValue: (json['totalValue'] ?? json['total_value'])?.toString() ?? '0',
      totalProducts: (json['totalProducts'] ?? json['total_products'] as num?)?.toInt() ?? 0,
      productsWithStock:
          (json['productsWithStock'] ?? json['products_with_stock'] as num?)?.toInt() ?? 0,
    );
  }

  final String totalValue;
  final int totalProducts;
  final int productsWithStock;
}

/// Produto em estoque baixo
class LowStockProduct {
  LowStockProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.deficit,
    this.code,
    this.category,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    final current = (json['currentStock'] ?? json['current_stock'] as num?)?.toInt() ?? 0;
    final min = (json['minStock'] ?? json['min_stock'] as num?)?.toInt() ?? 0;
    return LowStockProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'un',
      currentStock: current,
      minStock: min,
      deficit: (json['deficit'] as num?)?.toInt() ?? (min - current).clamp(0, 0x7fffffff),
      code: json['code'] as String?,
      category: json['category'] as String?,
    );
  }

  final String id;
  final String name;
  final String unit;
  final int currentStock;
  final int minStock;
  final int deficit;
  final String? code;
  final String? category;
}

class PaginationInfo {
  PaginationInfo({
    required this.total,
    this.page,
    this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
    );
  }

  final int total;
  final int? page;
  final int? limit;
}

class LowStockResponse {
  LowStockResponse({
    required this.products,
    required this.pagination,
  });

  factory LowStockResponse.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>?;
    return LowStockResponse(
      products: list
              ?.map((e) => LowStockProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? {'total': 0},
      ),
    );
  }

  final List<LowStockProduct> products;
  final PaginationInfo pagination;
}

/// Item do estoque atual (GET /stock/current)
class CurrentStockProduct {
  CurrentStockProduct({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
  });

  factory CurrentStockProduct.fromJson(Map<String, dynamic> json) {
    return CurrentStockProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] ?? json['currentStock'] ?? json['current_stock'] as num?)?.toInt(),
      unit: json['unit'] as String?,
    );
  }

  final String id;
  final String name;
  final int? quantity;
  final String? unit;
}

class CurrentStockResponse {
  CurrentStockResponse({
    required this.products,
    required this.pagination,
  });

  factory CurrentStockResponse.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>?;
    return CurrentStockResponse(
      products: list
              ?.map((e) => CurrentStockProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? {'total': 0},
      ),
    );
  }

  final List<CurrentStockProduct> products;
  final PaginationInfo pagination;
}

/// Uso diário (GET /stock/daily-usage)
class DailyUsageProduct {
  DailyUsageProduct({
    required this.product,
    required this.totalQuantity,
    this.exits = const [],
  });

  factory DailyUsageProduct.fromJson(Map<String, dynamic> json) {
    final p = json['product'] as Map<String, dynamic>?;
    return DailyUsageProduct(
      product: ProductInfo.fromJson(p ?? {}),
      totalQuantity: (json['totalQuantity'] ?? json['total_quantity'] as num?)?.toInt() ?? 0,
      exits: (json['exits'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  final ProductInfo product;
  final int totalQuantity;
  final List<dynamic> exits;
}

class ProductInfo {
  ProductInfo({required this.id, required this.name, this.unit});

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String?,
    );
  }

  final String id;
  final String name;
  final String? unit;
}

class DailyUsageResponse {
  DailyUsageResponse({
    required this.date,
    required this.products,
    this.totalExits = 0,
  });

  factory DailyUsageResponse.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>?;
    return DailyUsageResponse(
      date: json['date'] as String? ?? '',
      products: list
              ?.map((e) => DailyUsageProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalExits: (json['totalExits'] ?? json['total_exits'] as num?)?.toInt() ?? 0,
    );
  }

  final String date;
  final List<DailyUsageProduct> products;
  final int totalExits;
}
