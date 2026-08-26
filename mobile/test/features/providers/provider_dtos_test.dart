import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/providers/data/provider_dtos.dart';

/// Fixtures modeled on the backend's real responses: raw Prisma
/// models from `prisma/seed.ts` (VIAC) for `/providers` and
/// `/providers/:slug`, `ProductComparison` from `provider.types.ts`
/// for `/providers/compare` and `/providers/best-match`.

/// Response from `GET /providers`: products with `fees`, WITHOUT
/// `performanceHistory` (not included by `getAllProviders`).
const _viacListJson = <String, dynamic>{
  'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'slug': 'viac',
  'name': 'VIAC',
  'description': 'Pilier 3a digital avec fonds indiciels',
  'website': 'https://viac.ch',
  'isDigital': true,
  'isActive': true,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'products': [
    {
      'id': 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
      'providerId': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      'name': 'VIAC Global 100',
      'slug': 'viac-global-100',
      'investmentCategory': 'PASSIVE_INDEX',
      'riskLevel': 'AGGRESSIVE',
      'equityAllocation': 97,
      'sustainableEsg': false,
      'isActive': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'fees': {
        'id': 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
        'productId': 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
        'terPercent': 0,
        'custodyFeePercent': null,
        'allInFeePercent': 0.44,
        'entryFeePercent': 0,
        'exitFeePercent': 0,
        'notes': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      },
    },
  ],
};

/// Response from `GET /providers/:slug`: `performanceHistory` included
/// (descending year), product without a fee row is possible.
const _raiffeisenDetailJson = <String, dynamic>{
  'id': 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
  'slug': 'raiffeisen',
  'name': 'Raiffeisen',
  'description': 'Compte epargne et fonds 3a Raiffeisen',
  'website': 'https://raiffeisen.ch',
  'isDigital': false,
  'isActive': true,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'products': [
    {
      'id': 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
      'providerId': 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
      'name': 'Raiffeisen Futura Pension Invest',
      'slug': 'raiffeisen-futura-pension',
      'investmentCategory': 'ACTIVE_MANAGED',
      'riskLevel': 'BALANCED',
      'equityAllocation': 45,
      'sustainableEsg': true,
      'isActive': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'fees': {
        'id': 'f5eebc99-9c0b-4ef8-bb6d-6bb9bd380a66',
        'productId': 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
        'terPercent': 1.15,
        'custodyFeePercent': 0.25,
        'allInFeePercent': 1.15,
        'entryFeePercent': 0,
        'exitFeePercent': 0,
        'notes': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      },
      'performanceHistory': [
        {
          'id': '06eebc99-9c0b-4ef8-bb6d-6bb9bd380a77',
          'productId': 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
          'year': 2025,
          'returnPercent': 4.8,
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
        {
          'id': '17eebc99-9c0b-4ef8-bb6d-6bb9bd380a88',
          'productId': 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
          'year': 2024,
          'returnPercent': 9.8,
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
        {
          'id': '28eebc99-9c0b-4ef8-bb6d-6bb9bd380a99',
          'productId': 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
          'year': 2022,
          'returnPercent': -9.0,
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
      ],
    },
  ],
};

/// Element from `GET /providers/compare` / `POST /providers/best-match`
/// (`ProductComparison`) — `avgReturn3y`/`avgReturn5y` are nullable.
const _scoredJson = <String, dynamic>{
  'productId': 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'providerName': 'finpension',
  'providerSlug': 'finpension',
  'productName': 'finpension Equity 100',
  'productSlug': 'finpension-equity-100',
  'riskLevel': 'AGGRESSIVE',
  'equityAllocation': 99,
  'allInFeePercent': 0.39,
  'sustainableEsg': false,
  'avgReturn3y': 14.27,
  'avgReturn5y': 8.47,
  'score': 92,
};

void main() {
  group('ProviderDto (GET /providers)', () {
    test('provider + product + fees parsed, empty history', () {
      final provider = ProviderDto.fromJson(_viacListJson);

      expect(provider.slug, 'viac');
      expect(provider.name, 'VIAC');
      expect(provider.isDigital, isTrue);
      expect(provider.products, hasLength(1));

      final product = provider.products.single;
      expect(product.investmentCategory, 'PASSIVE_INDEX');
      expect(product.riskLevel, 'AGGRESSIVE');
      expect(product.equityAllocation, 97);
      expect(product.sustainableEsg, isFalse);
      // The list doesn't include performance history.
      expect(product.performanceHistory, isEmpty);

      final fees = product.fees!;
      // terPercent: 0 (int JSON) → double 0.0.
      expect(fees.terPercent, 0.0);
      expect(fees.allInFeePercent, 0.44);
      expect(fees.custodyFeePercent, isNull);
      expect(fees.entryFeePercent, 0.0);
    });
  });

  group('ProviderDto (GET /providers/:slug)', () {
    test('performance history parsed (descending year, negative ok)', () {
      final provider = ProviderDto.fromJson(_raiffeisenDetailJson);

      expect(provider.isDigital, isFalse);
      final product = provider.products.single;
      expect(product.sustainableEsg, isTrue);
      expect(product.fees!.custodyFeePercent, 0.25);

      final history = product.performanceHistory;
      expect(history, hasLength(3));
      expect(history.first.year, 2025);
      expect(history.first.returnPercent, 4.8);
      expect(history.last.returnPercent, -9.0);
    });

    test('product without a fee row: null fees tolerated', () {
      final json = Map<String, dynamic>.from(_raiffeisenDetailJson);
      final product = Map<String, dynamic>.from(
        (json['products'] as List).first as Map<String, dynamic>,
      );
      product['fees'] = null;
      json['products'] = [product];

      final provider = ProviderDto.fromJson(json);
      expect(provider.products.single.fees, isNull);
    });
  });

  group('ScoredProductDto (compare / best-match)', () {
    test('scored product parsed', () {
      final scored = ScoredProductDto.fromJson(_scoredJson);

      expect(scored.productId, 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22');
      expect(scored.providerName, 'finpension');
      expect(scored.allInFeePercent, 0.39);
      expect(scored.avgReturn3y, 14.27);
      expect(scored.avgReturn5y, 8.47);
      expect(scored.score, 92);
    });

    test('null returns tolerated (less than 3 years of history)', () {
      final json = Map<String, dynamic>.from(_scoredJson)
        ..['avgReturn3y'] = null
        ..['avgReturn5y'] = null;

      final scored = ScoredProductDto.fromJson(json);
      expect(scored.avgReturn3y, isNull);
      expect(scored.avgReturn5y, isNull);
    });
  });
}
