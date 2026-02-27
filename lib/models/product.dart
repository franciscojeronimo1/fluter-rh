/// Produto do estoque.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.minStock,
    required this.unit,
    required this.active,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.sku,
    this.category,
    this.costPrice,
    this.averageCost,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      sku: json['sku'] as String?,
      category: json['category'] as String?,
      currentStock: (json['currentStock'] ?? json['current_stock'] as num?)?.toInt() ?? 0,
      minStock: (json['minStock'] ?? json['min_stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'UN',
      costPrice: (json['costPrice'] ?? json['cost_price'])?.toString(),
      averageCost: (json['averageCost'] ?? json['average_cost'])?.toString(),
      active: json['active'] as bool? ?? true,
      organizationId: json['organizationId'] ?? json['organization_id'] as String? ?? '',
      createdAt: json['createdAt'] ?? json['created_at'] as String? ?? '',
      updatedAt: json['updatedAt'] ?? json['updated_at'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String? code;
  final String? sku;
  final String? category;
  final int currentStock;
  final int minStock;
  final String unit;
  final String? costPrice;
  final String? averageCost;
  final bool active;
  final String organizationId;
  final String createdAt;
  final String updatedAt;

  bool get isLowStock => currentStock < minStock;
}

/// Informações de paginação para listagens.
class ProductPaginationInfo {
  ProductPaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ProductPaginationInfo.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final limit = (json['limit'] as num?)?.toInt() ?? 10;
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final totalPages = (json['totalPages'] ?? json['total_pages'] as num?)?.toInt() ?? 1;
    return ProductPaginationInfo(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: (json['hasNext'] ?? json['has_next'] as bool?) ?? false,
      hasPrev: (json['hasPrev'] ?? json['has_prev'] as bool?) ?? false,
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
}

/// Resposta da listagem de produtos.
class ProductsResponse {
  ProductsResponse({
    required this.products,
    required this.pagination,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>?;
    return ProductsResponse(
      products: list
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: ProductPaginationInfo.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  final List<Product> products;
  final ProductPaginationInfo pagination;
}
