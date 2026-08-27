/// 3a provider DTOs — shapes verified against
/// `src/modules/provider/provider.service.ts` (raw Prisma `include`,
/// no envelope), `provider.types.ts` (`ProductComparison`) and
/// `prisma/schema.prisma` (`Pillar3aProvider`, `Pillar3aProduct`,
/// `Pillar3aProductFee`, `Pillar3aPerformance`).
///
/// - `GET /providers` and `GET /providers/:slug` return the raw
///   Prisma model ([ProviderDto]); only the detail endpoint includes
///   `performanceHistory` (the list only includes `fees`).
/// - `GET /providers/compare` and `POST /providers/best-match` return
///   scored products ([ScoredProductDto]).
///
/// Rates in percent (`0.44` = 0.44%), never amounts here.
library;

/// Fees for a 3a product (`Pillar3aProductFee`). A product with no
/// fee row has `fees == null` (optional relation).
class ProductFeeDto {
  const ProductFeeDto({
    required this.terPercent,
    this.custodyFeePercent,
    required this.allInFeePercent,
    required this.entryFeePercent,
    required this.exitFeePercent,
    this.notes,
  });

  /// Total Expense Ratio (fund fees), in percent.
  final double terPercent;

  /// Custody fees, in percent — null if not provided.
  final double? custodyFeePercent;

  /// All-in fees (what matters to the user), in percent.
  final double allInFeePercent;

  /// Entry fees, in percent (0 in the seed).
  final double entryFeePercent;

  /// Exit fees, in percent (0 in the seed).
  final double exitFeePercent;

  final String? notes;

  factory ProductFeeDto.fromJson(Map<String, dynamic> json) => ProductFeeDto(
    terPercent: (json['terPercent'] as num).toDouble(),
    custodyFeePercent: (json['custodyFeePercent'] as num?)?.toDouble(),
    allInFeePercent: (json['allInFeePercent'] as num).toDouble(),
    entryFeePercent: (json['entryFeePercent'] as num? ?? 0).toDouble(),
    exitFeePercent: (json['exitFeePercent'] as num? ?? 0).toDouble(),
    notes: json['notes'] as String?,
  );
}

/// One year of performance (`Pillar3aPerformance`), exposed only by
/// `GET /providers/:slug` (sorted by descending year by the backend).
class ProductPerformanceDto {
  const ProductPerformanceDto({
    required this.year,
    required this.returnPercent,
  });

  final int year;

  /// The year's return, in percent (can be negative).
  final double returnPercent;

  factory ProductPerformanceDto.fromJson(Map<String, dynamic> json) =>
      ProductPerformanceDto(
        year: (json['year'] as num).toInt(),
        returnPercent: (json['returnPercent'] as num).toDouble(),
      );
}

/// A 3a product as returned in `products` of the provider endpoints.
/// `investmentCategory`:
/// `PASSIVE_INDEX | ACTIVE_MANAGED | INSURANCE | SAVINGS_ACCOUNT`;
/// `riskLevel`: `CONSERVATIVE | MODERATE | BALANCED | GROWTH |
/// AGGRESSIVE`.
class ProviderProductDto {
  const ProviderProductDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.investmentCategory,
    required this.riskLevel,
    required this.equityAllocation,
    required this.sustainableEsg,
    this.fees,
    this.performanceHistory = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String investmentCategory;
  final String riskLevel;

  /// Equity share, 0–100%.
  final int equityAllocation;
  final bool sustainableEsg;
  final ProductFeeDto? fees;

  /// Annual history — empty on `GET /providers` (not included),
  /// populated on `GET /providers/:slug`.
  final List<ProductPerformanceDto> performanceHistory;

  factory ProviderProductDto.fromJson(Map<String, dynamic> json) =>
      ProviderProductDto(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        investmentCategory: json['investmentCategory'] as String,
        riskLevel: json['riskLevel'] as String,
        equityAllocation: (json['equityAllocation'] as num).toInt(),
        sustainableEsg: json['sustainableEsg'] as bool,
        fees: json['fees'] == null
            ? null
            : ProductFeeDto.fromJson(json['fees'] as Map<String, dynamic>),
        performanceHistory: [
          for (final item
              in json['performanceHistory'] as List<dynamic>? ?? const [])
            ProductPerformanceDto.fromJson(item as Map<String, dynamic>),
        ],
      );
}

/// A 3a provider with its products (`GET /providers`,
/// `GET /providers/:slug`).
class ProviderDto {
  const ProviderDto({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.website,
    required this.isDigital,
    this.products = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? website;
  final bool isDigital;
  final List<ProviderProductDto> products;

  factory ProviderDto.fromJson(Map<String, dynamic> json) => ProviderDto(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    website: json['website'] as String?,
    isDigital: json['isDigital'] as bool? ?? false,
    products: [
      for (final item in json['products'] as List<dynamic>? ?? const [])
        ProviderProductDto.fromJson(item as Map<String, dynamic>),
    ],
  );
}

/// Scored product (backend `ProductComparison`) — response from
/// `GET /providers/compare` and `POST /providers/best-match`, sorted
/// by descending score on the backend side.
class ScoredProductDto {
  const ScoredProductDto({
    required this.productId,
    required this.providerName,
    required this.providerSlug,
    required this.productName,
    required this.productSlug,
    required this.riskLevel,
    required this.equityAllocation,
    required this.allInFeePercent,
    required this.sustainableEsg,
    this.avgReturn3y,
    this.avgReturn5y,
    required this.score,
  });

  final String productId;
  final String providerName;
  final String providerSlug;
  final String productName;
  final String productSlug;
  final String riskLevel;

  /// Equity share, 0–100%.
  final int equityAllocation;

  /// All-in fees, in percent (0 if the product has no fee row — the
  /// backend applies `?? 0`).
  final double allInFeePercent;
  final bool sustainableEsg;

  /// Average return over 3 years, in percent — null if less than 3
  /// years of history.
  final double? avgReturn3y;

  /// Average return over 5 years, in percent — null if less than 5 years.
  final double? avgReturn5y;

  /// Score 0–100 (fees 40% / performance 30% / risk 20% / ESG 10% —
  /// ESG weighting differs in best-match).
  final int score;

  factory ScoredProductDto.fromJson(Map<String, dynamic> json) =>
      ScoredProductDto(
        productId: json['productId'] as String,
        providerName: json['providerName'] as String,
        providerSlug: json['providerSlug'] as String,
        productName: json['productName'] as String,
        productSlug: json['productSlug'] as String,
        riskLevel: json['riskLevel'] as String,
        equityAllocation: (json['equityAllocation'] as num).toInt(),
        allInFeePercent: (json['allInFeePercent'] as num).toDouble(),
        sustainableEsg: json['sustainableEsg'] as bool,
        avgReturn3y: (json['avgReturn3y'] as num?)?.toDouble(),
        avgReturn5y: (json['avgReturn5y'] as num?)?.toDouble(),
        score: (json['score'] as num).toInt(),
      );
}
