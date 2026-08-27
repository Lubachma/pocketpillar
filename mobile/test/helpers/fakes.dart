import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/purchases/premium_status.dart';
import 'package:pocketpillar/core/purchases/purchases_service.dart';
import 'package:pocketpillar/features/couple/data/couple_payloads.dart';
import 'package:pocketpillar/features/couple/data/couple_repository.dart';
import 'package:pocketpillar/features/couple/data/couple_result.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart'
    hide FinancialProfileDto, Pillar2AccountDto, Pillar3aAccountDto;
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/documents/application/documents_providers.dart';
import 'package:pocketpillar/features/documents/data/document_dtos.dart';
import 'package:pocketpillar/features/documents/data/document_repository.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/municipality.dart';
import 'package:pocketpillar/features/providers/data/provider_dtos.dart';
import 'package:pocketpillar/features/providers/data/provider_repository.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_dtos.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_repository.dart';
import 'package:pocketpillar/features/settings/data/account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simulated auth repository (no real Supabase client).
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(null);

  Object? signInError;
  Object? signUpError;
  SignUpResult signUpResult = const SignUpResult.withSession(
    AuthIdentity(userId: 'supa-123', email: 'user@example.ch'),
  );

  String? lastEmail;
  String? lastPassword;
  int signOutCalls = 0;

  /// Error thrown by `signOut` while set (e.g. network revoke after
  /// account deletion — review batch 3.10).
  Object? signOutError;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    final error = signInError;
    if (error != null) throw error;
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    final error = signUpError;
    if (error != null) throw error;
    return signUpResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) throw error;
  }
}

/// Simulated API client: records calls, can throw an error.
class FakeApiClient extends ApiClient {
  FakeApiClient()
    : super(
        baseUrl: 'http://localhost:0',
        getAccessToken: () => null,
        refreshAccessToken: () async => null,
        onAuthExpired: () async {},
        getLanguage: () => 'fr',
      );

  final List<({String path, Object? data})> postCalls = [];
  Object? postError;

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls.add((path: path, data: data));
    final error = postError;
    if (error != null) throw error;
    return Response<T>(requestOptions: RequestOptions(), statusCode: 201);
  }
}

/// Simulated scenario repository: boxed results per scenario, records
/// the last payload, configurable one-off (`failOnce`) or persistent
/// (`error` — e.g. 400 EPL) failure.
class FakeScenarioRepository extends ScenarioRepository {
  FakeScenarioRepository() : super(FakeApiClient());

  Catchup3aResultDto? catchupResult;
  StaggeredWithdrawalResultDto? staggeredResult;
  PropertyPurchaseResultDto? propertyResult;
  DivorceImpactResultDto? divorceResult;

  /// Error thrown while set (e.g. `ApiException` 400).
  Object? error;

  /// Network failure on the first call only (to test the retry).
  bool failOnce = false;

  int calls = 0;
  Map<String, dynamic>? lastPayload;

  Future<T> _run<T>(T? result, Map<String, dynamic> payload) async {
    lastPayload = payload;
    final call = ++calls;
    final persistent = error;
    if (persistent != null) throw persistent;
    if (failOnce && call == 1) throw const NetworkException();
    return result!;
  }

  @override
  Future<Catchup3aResultDto> catchup3a(Map<String, dynamic> payload) =>
      _run(catchupResult, payload);

  @override
  Future<StaggeredWithdrawalResultDto> staggeredWithdrawal(
    Map<String, dynamic> payload,
  ) => _run(staggeredResult, payload);

  @override
  Future<PropertyPurchaseResultDto> propertyPurchase(
    Map<String, dynamic> payload,
  ) => _run(propertyResult, payload);

  @override
  Future<DivorceImpactResultDto> divorceImpact(Map<String, dynamic> payload) =>
      _run(divorceResult, payload);
}

/// Simulated couple repository: boxed result, records both inputs
/// and the tax situation, configurable one-off (`failOnce`) or
/// persistent (`error`) failure.
class FakeCoupleRepository extends CoupleRepository {
  FakeCoupleRepository() : super(FakeApiClient());

  CoupleResult? result;

  /// Error thrown while set.
  Object? error;

  /// Network failure on the first call only (to test the retry).
  bool failOnce = false;

  int calls = 0;
  CoupleSpouseInput? lastPerson1;
  CoupleSpouseInput? lastPerson2;
  String? lastCanton;
  String? lastMunicipality;
  String? lastMaritalStatus;

  @override
  Future<CoupleResult> simulate({
    required CoupleSpouseInput person1,
    required CoupleSpouseInput person2,
    required String canton,
    String? municipality,
    required String maritalStatus,
  }) async {
    lastPerson1 = person1;
    lastPerson2 = person2;
    lastCanton = canton;
    lastMunicipality = municipality;
    lastMaritalStatus = maritalStatus;
    final call = ++calls;
    final persistent = error;
    if (persistent != null) throw persistent;
    if (failOnce && call == 1) throw const NetworkException();
    return result!;
  }
}

/// Simulated provider repository: boxed catalog / ranking / detail /
/// best match, records the last parameters, configurable one-off
/// (`failOnce`) or persistent (`error`) failure.
class FakeProviderRepository extends ProviderRepository {
  FakeProviderRepository() : super(FakeApiClient());

  List<ProviderDto> providers = [];
  List<ScoredProductDto> scored = [];
  List<ScoredProductDto> bestMatchResults = [];
  ProviderDto? detail;

  /// True → `getProvider` returns null (404 → "not found" state).
  bool detailNotFound = false;

  /// Error thrown while set.
  Object? error;

  /// Network failure on the first call only (to test the retry).
  bool failOnce = false;

  int calls = 0;
  String? lastCompareRiskLevel;
  String? lastBestMatchRiskLevel;
  bool? lastPreferEsg;
  double? lastMaxFeePercent;
  String? lastSlug;

  Future<T> _run<T>(T result) async {
    final call = ++calls;
    final persistent = error;
    if (persistent != null) throw persistent;
    if (failOnce && call == 1) throw const NetworkException();
    return result;
  }

  @override
  Future<List<ProviderDto>> listProviders() => _run(providers);

  @override
  Future<List<ScoredProductDto>> compareProducts({
    String? riskLevel,
    bool sustainableOnly = false,
    double? maxFeePercent,
  }) {
    lastCompareRiskLevel = riskLevel;
    return _run(scored);
  }

  @override
  Future<ProviderDto?> getProvider(String slug) {
    lastSlug = slug;
    return _run(detailNotFound ? null : detail);
  }

  @override
  Future<List<ScoredProductDto>> bestMatch({
    required String riskLevel,
    required bool preferEsg,
    double? maxFeePercent,
  }) {
    lastBestMatchRiskLevel = riskLevel;
    lastPreferEsg = preferEsg;
    lastMaxFeePercent = maxFeePercent;
    return _run(bestMatchResults);
  }
}

/// Simulated document repository: boxed list (upload adds to it,
/// delete removes from it), records calls, configurable one-off
/// (`failOnce`) or persistent (`error`) failure.
class FakeDocumentRepository extends DocumentRepository {
  FakeDocumentRepository() : super(FakeApiClient());

  List<DocumentDto> documents = [];

  DocumentDownloadDto download = const DocumentDownloadDto(
    url: 'https://example.ch/signed-url',
    filename: 'fiche.pdf',
    mimeType: 'application/pdf',
  );

  /// Error thrown while set (all methods).
  Object? error;

  /// Error thrown by `deleteDocument` only (e.g. 404 → tests the list
  /// resync, review batch 3.8 #2).
  Object? deleteError;

  /// Network failure on the first call only (to test the retry).
  bool failOnce = false;

  int calls = 0;
  int uploadCalls = 0;
  String? lastUploadType;
  int? lastUploadYear;
  String? lastUploadFilename;
  int? lastUploadSize;
  final List<String> deletedIds = [];
  final List<String> downloadIds = [];

  /// If set, the upload awaits this completer — lets the sheet be
  /// closed while sending (test review batch 3.8 #3).
  Completer<void>? uploadGate;

  Future<T> _run<T>(T result) async {
    final call = ++calls;
    final persistent = error;
    if (persistent != null) throw persistent;
    if (failOnce && call == 1) throw const NetworkException();
    return result;
  }

  @override
  Future<List<DocumentDto>> listDocuments() {
    listCalls++;
    return _run(documents);
  }

  int listCalls = 0;

  @override
  Future<DocumentDto> uploadDocument({
    required String type,
    required String filename,
    required Uint8List bytes,
    int? year,
    ProgressCallback? onSendProgress,
  }) async {
    uploadCalls++;
    lastUploadType = type;
    lastUploadYear = year;
    lastUploadFilename = filename;
    lastUploadSize = bytes.length;
    onSendProgress?.call(bytes.length, bytes.length);
    final gate = uploadGate;
    if (gate != null) await gate.future;
    final uploaded = DocumentDto(
      id: 'doc-new-$uploadCalls',
      type: type,
      filename: filename,
      mimeType: 'application/pdf',
      sizeBytes: bytes.length,
      year: year,
      uploadedAt: DateTime.utc(2026, 8, 5),
    );
    await _run(null);
    // Like the backend: the document appears in the reloaded list.
    documents = [uploaded, ...documents];
    return uploaded;
  }

  @override
  Future<DocumentDownloadDto> getDownloadUrl(String id) async {
    downloadIds.add(id);
    return _run(download);
  }

  @override
  Future<void> deleteDocument(String id) async {
    deletedIds.add(id);
    final deleteFailure = deleteError;
    if (deleteFailure != null) throw deleteFailure;
    await _run(null);
    documents = [
      for (final doc in documents)
        if (doc.id != id) doc,
    ];
  }
}

/// Simulated file picker: boxed result (default: cancelled —
/// silent).
class FakeDocumentFilePicker implements DocumentFilePicker {
  DocumentPickResult result = const DocumentPickCancelled();
  int calls = 0;

  @override
  Future<DocumentPickResult> pick() async {
    calls++;
    return result;
  }
}

/// Simulated dashboard repository: boxed data, configurable one-off
/// failure to test the retry (`failLoadOnce` /
/// `failRecommendationsOnce` / `failScoreOnce`).
class FakeDashboardRepository extends DashboardRepository {
  FakeDashboardRepository() : super(FakeApiClient());

  DashboardData? data;
  RecommendationResultDto? recommendations;
  PensionScoreDto? score;
  bool failLoadOnce = false;
  bool failRecommendationsOnce = false;
  bool failScoreOnce = false;

  int loadCalls = 0;
  int recommendationsCalls = 0;
  int scoreCalls = 0;

  /// The received aggregate is ignored: the boxed data takes precedence (I9).
  @override
  Future<DashboardData> loadFrom(ProfileAggregate aggregate) async {
    final call = ++loadCalls;
    if (failLoadOnce && call == 1) throw const NetworkException();
    return data!;
  }

  @override
  Future<RecommendationResultDto?> loadRecommendations() async {
    final call = ++recommendationsCalls;
    if (failRecommendationsOnce && call == 1) {
      throw const NetworkException();
    }
    return recommendations;
  }

  @override
  Future<PensionScoreDto?> loadScore() async {
    final call = ++scoreCalls;
    if (failScoreOnce && call == 1) throw const NetworkException();
    return score;
  }
}

/// Fake Supabase session (signed-in user, configurable email).
Session buildFakeSession({String email = 'user@example.ch'}) => Session(
  accessToken: 'fake-token',
  tokenType: 'bearer',
  user: User(
    id: 'supa-123',
    appMetadata: const {},
    userMetadata: null,
    aud: 'authenticated',
    createdAt: '2026-08-05T00:00:00.000Z',
    email: email,
  ),
);

/// Simulated auth repository starting **signed in**: the fake session
/// is emitted immediately; `signOut` emits null — the real router
/// then redirects to /login (Settings integration tests).
class SignedInFakeAuthRepository extends FakeAuthRepository {
  SignedInFakeAuthRepository({String email = 'user@example.ch'})
    : _current = buildFakeSession(email: email);

  final StreamController<Session?> _controller =
      StreamController<Session?>.broadcast();
  Session? _current;

  @override
  Session? get currentSession => _current;

  @override
  String? get currentEmail => _current?.user.email;

  @override
  Stream<Session?> get sessionChanges async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signOut() async {
    await super.signOut();
    _current = null;
    _controller.add(null);
  }
}

/// Simulated notification service: records calls and the scheduled
/// localized bodies; configurable permission.
class FakeNotificationService implements NotificationService {
  int initializeCalls = 0;
  int requestPermissionCalls = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;

  /// Permission to return (default: granted).
  bool permissionGranted = true;

  String? lastYearEndChecklistBody;
  String? lastPillar3aBody;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleAnnualReminders({
    required String yearEndChecklistBody,
    required String pillar3aBody,
  }) async {
    scheduleCalls++;
    lastYearEndChecklistBody = yearEndChecklistBody;
    lastPillar3aBody = pillar3aBody;
  }

  @override
  Future<void> cancelAnnualReminders() async {
    cancelCalls++;
  }
}

/// Simulated financial profile repository: boxed 3a accounts and
/// profile, boxed municipalities, counted calls, configurable error
/// (contextual pillar 3a reminder, batch 7).
class FakeFinancialProfileRepository extends FinancialProfileRepository {
  FakeFinancialProfileRepository() : super(FakeApiClient());

  List<Pillar3aAccountDto> pillar3aAccounts = [];
  List<Pillar2AccountDto> pillar2Accounts = [];
  FinancialProfileDto? profile;

  /// Municipalities returned by `fetchMunicipalities` (regardless of
  /// the canton requested).
  List<MunicipalityInfo> municipalities = [];

  /// Error thrown while set (e.g. `NetworkException`).
  Object? error;

  int fetchPillar3aCalls = 0;
  int fetchPillar2Calls = 0;
  int fetchProfileCalls = 0;
  int fetchMunicipalitiesCalls = 0;

  /// Last canton requested from `fetchMunicipalities`.
  String? lastMunicipalitiesCanton;

  @override
  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async {
    fetchPillar3aCalls++;
    final failure = error;
    if (failure != null) throw failure;
    return pillar3aAccounts;
  }

  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async {
    fetchPillar2Calls++;
    final failure = error;
    if (failure != null) throw failure;
    return pillar2Accounts;
  }

  @override
  Future<FinancialProfileDto?> fetchProfileOrNull() async {
    fetchProfileCalls++;
    final failure = error;
    if (failure != null) throw failure;
    return profile;
  }

  @override
  Future<List<MunicipalityInfo>> fetchMunicipalities(String canton) async {
    fetchMunicipalitiesCalls++;
    lastMunicipalitiesCanton = canton;
    final failure = error;
    if (failure != null) throw failure;
    return municipalities;
  }
}

/// Simulated account repository: records deletions, configurable
/// error (`ApiException`, `NetworkException`...).
class FakeAccountRepository extends AccountRepository {
  FakeAccountRepository() : super(FakeApiClient());

  int deleteCalls = 0;

  /// Error thrown by `deleteAccount` while set.
  Object? error;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    final persistent = error;
    if (persistent != null) throw persistent;
  }
}

/// Simulated purchases service (RevenueCat): boxed outcomes, calls
/// recorded; `purchaseGate` lets the in-progress purchase be frozen to
/// test the paywall's "purchasing" state.
class FakePurchasesService implements PurchasesService {
  bool available = true;

  /// Offer returned by `fetchAnnualOffering` (null = no offering
  /// published → paywall's "purchase unavailable" state).
  PremiumOffering? offering = const PremiumOffering(priceLabel: 'CHF 39.00');

  /// Error thrown by `fetchAnnualOffering` while set (e.g. store
  /// network) — the screen shows the error state with retry.
  Object? offeringError;

  PurchaseOutcome purchaseOutcome = PurchaseOutcome.success;
  RestoreOutcome restoreOutcome = RestoreOutcome.restored;

  /// If set, `purchaseAnnual` awaits this completer (observable
  /// "purchase in progress" state).
  Completer<void>? purchaseGate;

  final List<String> logIns = [];
  int logOutCalls = 0;
  int offeringCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<void> logIn(String backendUserId) async {
    logIns.add(backendUserId);
  }

  @override
  Future<void> logOut() async {
    logOutCalls++;
  }

  @override
  Future<PremiumOffering?> fetchAnnualOffering() async {
    offeringCalls++;
    if (!available) return null;
    final failure = offeringError;
    if (failure != null) throw failure;
    return offering;
  }

  @override
  Future<PurchaseOutcome> purchaseAnnual() async {
    purchaseCalls++;
    if (!available) return PurchaseOutcome.unavailable;
    final gate = purchaseGate;
    if (gate != null) await gate.future;
    return purchaseOutcome;
  }

  @override
  Future<RestoreOutcome> restore() async {
    restoreCalls++;
    if (!available) return RestoreOutcome.unavailable;
    return restoreOutcome;
  }
}

/// Minimal fake profile aggregate (I9): inject via
/// `profileAggregateProvider.overrideWith(() => FakeProfileAggregateNotifier(…))`
/// in screen tests that consume the aggregate indirectly
/// (dashboard...) without caring about its content.
/// [premium]: subscription status of the `users/me` block (§11), not
/// subscribed by default.
ProfileAggregate buildFakeProfileAggregate({
  PremiumStatus premium = PremiumStatus.none,
}) => ProfileAggregate(
  base: ProfileBaseData(
    userId: 'u-1',
    email: 'user@example.ch',
    replacementRateGoal: 70,
    premium: premium,
    loadedAt: DateTime(2026, 8, 5),
  ),
);

/// Fake aggregate notifier: boxed value, no network call.
class FakeProfileAggregateNotifier extends ProfileAggregateNotifier {
  FakeProfileAggregateNotifier(this._aggregate);

  final ProfileAggregate _aggregate;

  @override
  Future<ProfileAggregate> build() async => _aggregate;
}

/// Simulated profile repository that counts its calls (I9: deduplicating
/// the load across the 4 endpoints; invalidation on session transition).
class CountingFakeFinancialProfileRepository
    extends FinancialProfileRepository {
  CountingFakeFinancialProfileRepository() : super(FakeApiClient());

  int loadBaseCalls = 0;
  int fetchPillar2Calls = 0;
  int fetchPillar3aCalls = 0;

  ProfileBaseData base = ProfileBaseData(
    userId: 'u-1',
    email: 'user@example.ch',
    canton: 'VD',
    birthYear: 1991,
    replacementRateGoal: 70,
    loadedAt: DateTime(2026, 8, 5),
  );

  List<Pillar2AccountDto> pillar2Accounts = const [
    Pillar2AccountDto(
      id: 'p2-1',
      currentCapital: 100000,
      isVestedBenefits: false,
    ),
  ];

  List<Pillar3aAccountDto> pillar3aAccounts = const [];

  @override
  Future<ProfileBaseData> loadBase() async {
    loadBaseCalls++;
    return base;
  }

  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async {
    fetchPillar2Calls++;
    return pillar2Accounts;
  }

  @override
  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async {
    fetchPillar3aCalls++;
    return pillar3aAccounts;
  }
}
