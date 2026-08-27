import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';

/// Simulated API client: canned responses by path, exceptions possible.
class FakeDashboardApiClient extends ApiClient {
  FakeDashboardApiClient()
    : super(
        baseUrl: 'http://localhost:0',
        getAccessToken: () => null,
        refreshAccessToken: () async => null,
        onAuthExpired: () async {},
        getLanguage: () => 'fr',
      );

  /// Path → JSON (Map/List) or [Exception] to throw.
  final Map<String, Object> getResponses = {};

  /// JSON or [Exception] for the POST /calculator/retirement.
  Object? postResponse;

  final List<String> getCalls = [];
  ({String path, Object? data})? lastPost;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    getCalls.add(path);
    final stub = getResponses[path];
    if (stub == null) throw StateError('Aucun stub pour GET $path');
    if (stub is Exception) throw stub;
    return Response<T>(
      requestOptions: RequestOptions(),
      data: stub as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    lastPost = (path: path, data: data);
    final stub = postResponse;
    if (stub is Exception) throw stub;
    return Response<T>(
      requestOptions: RequestOptions(),
      data: stub as T,
      statusCode: 200,
    );
  }
}

Map<String, dynamic> _projectionJson() => {
  'yearsToRetirement': 30,
  'projectedPillar2Capital': 50000000,
  'projectedPillar3aBalance': 8000000,
  'annualPillar2Pension': 3000000,
  'estimatedAnnualAvsPension': 2352000,
  'pillar3aAsLumpSum': 8000000,
  'totalAnnualRetirementIncome': 5352000,
  'replacementRate': 62.96,
  'yearByYearProjection': <dynamic>[],
};

void main() {
  late FakeDashboardApiClient api;
  late DashboardRepository repository;

  final currentYear = DateTime.now().year;

  setUp(() {
    api = FakeDashboardApiClient();
    repository = DashboardRepository(api);
  });

  /// Canned profile aggregate (I9: the repository no longer fetches these
  /// endpoints, it composes from the shared aggregate).
  ProfileAggregate aggregate({
    int? birthYear = 1991,
    bool withProfile = true,
  }) => ProfileAggregate(
    base: ProfileBaseData(
      userId: 'u-1',
      email: 'user@example.ch',
      canton: 'VD',
      birthYear: birthYear,
      replacementRateGoal: 70,
      loadedAt: DateTime(2026, 8, 5),
      profile: withProfile
          ? const FinancialProfileDto(
              id: 'fp-1',
              employmentStatus: 'EMPLOYED',
              maritalStatus: 'SINGLE',
              numberOfChildren: 0,
              grossAnnualIncome: 8500000,
            )
          : null,
    ),
    pillar2Accounts: const [
      Pillar2AccountDto(
        id: 'p2-1',
        currentCapital: 1500000,
        annualBvgContribution: 400000,
        isVestedBenefits: false,
      ),
      Pillar2AccountDto(
        id: 'p2-2',
        currentCapital: 500000,
        annualBvgContribution: 100000,
        isVestedBenefits: false,
      ),
    ],
    pillar3aAccounts: const [
      Pillar3aAccountDto(
        id: 'p3-1',
        providerName: 'VIAC',
        accountType: 'BANK',
        currentBalance: 1000000,
        annualContribution: 700000,
      ),
    ],
  );

  group('loadFrom', () {
    test('full aggregate: DTOs mapped and projection requested', () async {
      api.postResponse = _projectionJson();

      final data = await repository.loadFrom(
        aggregate(birthYear: currentYear - 35),
      );

      expect(data.hasProfile, isTrue);
      expect(data.user.email, 'user@example.ch');
      expect(data.user.replacementRateGoal, 70);
      expect(data.profile!.grossAnnualIncome, 8500000);
      expect(data.totalPillar2Capital, 2000000);
      expect(data.totalPillar3aBalance, 1000000);
      expect(data.hasPillar3a, isTrue);
      expect(data.projection!.replacementRate, closeTo(62.96, 0.001));
      expect(data.projection!.totalAnnualRetirementIncome, 5352000);
      expect(data.projection!.annualPillar2Pension, 3000000);

      // Projection payload: computed age, summed amounts (centimes).
      final post = api.lastPost!;
      expect(post.path, '/calculator/retirement');
      final body = post.data! as Map<String, dynamic>;
      expect(body['currentAge'], 35);
      expect(body['retirementAge'], 65);
      expect(body['grossAnnualIncome'], 8500000);
      expect(body['currentPillar2Capital'], 2000000);
      expect(body['annualPillar2Contribution'], 500000);
      expect(body['currentPillar3aBalance'], 1000000);
      expect(body['annualPillar3aContribution'], 700000);
      // No duplicated AVS formula on the client side: backend default.
      expect(body.containsKey('estimatedAvsPension'), isFalse);
    });

    test(
      'aggregate without profile (initial 404) → empty state, no projection',
      () async {
        final data = await repository.loadFrom(aggregate(withProfile: false));

        expect(data.hasProfile, isFalse);
        expect(data.profile, isNull);
        expect(data.projection, isNull);
        // The calculator isn't called unnecessarily.
        expect(api.lastPost, isNull);
      },
    );

    test('birthYear missing → no call to the calculator', () async {
      final data = await repository.loadFrom(aggregate(birthYear: null));

      expect(data.hasProfile, isTrue);
      expect(data.projection, isNull);
      expect(api.lastPost, isNull);
    });

    test('age ≥ 65 → projection not calculable, no call', () async {
      final data = await repository.loadFrom(
        aggregate(birthYear: currentYear - 66),
      );

      expect(data.projection, isNull);
      expect(api.lastPost, isNull);
    });

    test('network error from the projection → propagated', () async {
      api.postResponse = const NetworkException();

      expect(
        repository.loadFrom(aggregate()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('loadRecommendations', () {
    test('200 → recommendations parsed', () async {
      api.getResponses['/recommendations'] = {
        'recommendations': [
          {
            'type': 'MAX_3A_CONTRIBUTION',
            'priority': 'HIGH',
            'title': 'Maximisez votre 3a',
            'description': 'Versez le maximum avant fin décembre.',
            'estimatedAnnualImpact': 215000,
            'estimatedLifetimeImpact': 5000000,
            'details': <String, dynamic>{},
          },
        ],
        'profileCompleteness': 80,
        'generatedAt': '2026-08-05T10:00:00.000Z',
      };

      final result = await repository.loadRecommendations();

      expect(result, isNotNull);
      expect(result!.recommendations, hasLength(1));
      final reco = result.recommendations.first;
      expect(reco.type, 'MAX_3A_CONTRIBUTION');
      expect(reco.priority, 'HIGH');
      expect(reco.estimatedAnnualImpact, 215000);
    });

    test('422 incomplete profile → null (empty state, not an error)', () async {
      api.getResponses['/recommendations'] = const ApiException(
        'Profil incomplet',
        statusCode: 422,
      );

      expect(await repository.loadRecommendations(), isNull);
    });

    test('network error → propagated', () async {
      api.getResponses['/recommendations'] = const NetworkException();

      expect(
        repository.loadRecommendations(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('loadScore', () {
    Map<String, dynamic> scoreJson() => {
      'score': 87,
      'breakdown': [
        {
          'criterion': 'REPLACEMENT_RATE',
          'label': 'Taux de remplacement',
          'points': 32,
          'maxPoints': 40,
        },
        {
          'criterion': 'PILLAR_3A',
          'label': 'Épargne 3a',
          'points': 30,
          'maxPoints': 30,
        },
        {
          'criterion': 'AGE_AWARENESS',
          'label': 'Horizon retraite',
          'points': 25,
          'maxPoints': 30,
        },
      ],
      'benchmark': {
        'bracket': {'minAge': 35, 'maxAge': 39},
        'averagePillar3aBalance': 4800000,
        'averageReplacementRate': 58,
        'averageBvgCapital': 12000000,
        'userPillar3aBalance': 4800000,
        'userReplacementRate': 65.0,
        'userBvgCapital': 12000000,
      },
      'generatedAt': '2026-08-06T10:00:00.000Z',
    };

    test('200 → score and benchmark parsed', () async {
      api.getResponses['/score'] = scoreJson();

      final result = await repository.loadScore();

      expect(result, isNotNull);
      expect(result!.score, 87);
      expect(result.breakdown, hasLength(3));
      expect(result.benchmark.bracketMinAge, 35);
      expect(result.benchmark.userReplacementRate, 65.0);
    });

    test('422 incomplete profile → null (card hidden, not an error)', () async {
      api.getResponses['/score'] = const ApiException(
        'Profil incomplet',
        statusCode: 422,
      );

      expect(await repository.loadScore(), isNull);
    });

    test('network error → propagated', () async {
      api.getResponses['/score'] = const NetworkException();

      expect(repository.loadScore(), throwsA(isA<NetworkException>()));
    });
  });
}
