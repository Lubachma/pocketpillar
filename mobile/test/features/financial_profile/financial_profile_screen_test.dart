import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/municipality.dart';
import 'package:pocketpillar/features/financial_profile/presentation/financial_profile_screen.dart';

import '../../helpers/fakes.dart';

/// Fake repository: canned data, calls recorded (payloads verified).
class FakeFinancialProfileRepository extends FinancialProfileRepository {
  FakeFinancialProfileRepository() : super(FakeApiClient());

  ProfileBaseData base = _base();
  Object? baseError;
  List<Pillar2AccountDto> pillar2 = [];
  List<Pillar3aAccountDto> pillar3a = [];

  /// Municipalities returned by `fetchMunicipalities` (Commune picker).
  List<MunicipalityInfo> municipalities = [];

  Map<String, Object?>? lastUserUpdate;
  Map<String, Object?>? lastProfileUpsert;
  final List<String> deletedPillar2Ids = [];
  final List<String> deletedPillar3aIds = [];
  Map<String, Object?>? lastPillar3aCreate;
  Map<String, Object?>? lastPillar2Create;

  /// Test lock: suspends `upsertProfile` until `complete()`.
  Completer<void>? saveGate;

  static ProfileBaseData _base({
    FinancialProfileDto? profile,
    String? canton = 'VD',
    String? municipality,
    int? birthYear = 1991,
  }) => ProfileBaseData(
    userId: 'u-1',
    email: 'user@example.ch',
    canton: canton,
    municipality: municipality,
    birthYear: birthYear,
    replacementRateGoal: 70,
    profile: profile,
    loadedAt: DateTime(2026, 8, 5),
  );

  @override
  Future<ProfileBaseData> loadBase() async {
    final error = baseError;
    if (error != null) throw error;
    return base;
  }

  @override
  Future<void> updateUser({
    String? canton,
    int? birthYear,
    int? replacementRateGoal,
    String? municipality,
    bool clearMunicipality = false,
  }) async {
    lastUserUpdate = {
      'canton': canton,
      'birthYear': birthYear,
      'replacementRateGoal': replacementRateGoal,
      'municipality': municipality,
      'clearMunicipality': clearMunicipality,
    };
  }

  @override
  Future<List<MunicipalityInfo>> fetchMunicipalities(String canton) async =>
      municipalities;

  @override
  Future<FinancialProfileDto> upsertProfile({
    required String employmentStatus,
    required String maritalStatus,
    required int numberOfChildren,
    required int grossAnnualIncome,
    int? netAnnualIncome,
  }) async {
    await saveGate?.future;
    lastProfileUpsert = {
      'employmentStatus': employmentStatus,
      'maritalStatus': maritalStatus,
      'numberOfChildren': numberOfChildren,
      'grossAnnualIncome': grossAnnualIncome,
      'netAnnualIncome': netAnnualIncome,
    };
    return FinancialProfileDto(
      id: 'fp-1',
      employmentStatus: employmentStatus,
      maritalStatus: maritalStatus,
      numberOfChildren: numberOfChildren,
      grossAnnualIncome: grossAnnualIncome,
      netAnnualIncome: netAnnualIncome,
    );
  }

  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async => pillar2;

  /// Error thrown by `fetchPillar3aAccounts` when set (tests the
  /// silent targeted reload — minor #6).
  Object? pillar3aFetchError;

  @override
  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async {
    final failure = pillar3aFetchError;
    if (failure != null) throw failure;
    return pillar3a;
  }

  @override
  Future<Pillar2AccountDto> createPillar2Account({
    String? providerName,
    required int currentCapital,
    double? conversionRate,
    int? insuredSalary,
    int? coordinationDeduction,
    int? annualBvgContribution,
    int? annualSupraContribution,
    required bool isVestedBenefits,
  }) async {
    lastPillar2Create = {
      'providerName': providerName,
      'currentCapital': currentCapital,
      'conversionRate': conversionRate,
      'insuredSalary': insuredSalary,
      'coordinationDeduction': coordinationDeduction,
      'annualBvgContribution': annualBvgContribution,
      'annualSupraContribution': annualSupraContribution,
      'isVestedBenefits': isVestedBenefits,
    };
    final account = Pillar2AccountDto(
      id: 'p2-new',
      providerName: providerName,
      currentCapital: currentCapital,
      conversionRate: conversionRate,
      insuredSalary: insuredSalary,
      coordinationDeduction: coordinationDeduction,
      annualBvgContribution: annualBvgContribution,
      annualSupraContribution: annualSupraContribution,
      isVestedBenefits: isVestedBenefits,
    );
    pillar2 = [...pillar2, account];
    return account;
  }

  @override
  Future<Pillar2AccountDto> updatePillar2Account(
    String id, {
    String? providerName,
    int? currentCapital,
    double? conversionRate,
    int? insuredSalary,
    int? coordinationDeduction,
    int? annualBvgContribution,
    int? annualSupraContribution,
    bool? isVestedBenefits,
  }) async {
    final existing = pillar2.firstWhere((a) => a.id == id);
    final account = Pillar2AccountDto(
      id: id,
      providerName: providerName ?? existing.providerName,
      currentCapital: currentCapital ?? existing.currentCapital,
      conversionRate: conversionRate ?? existing.conversionRate,
      insuredSalary: insuredSalary ?? existing.insuredSalary,
      coordinationDeduction:
          coordinationDeduction ?? existing.coordinationDeduction,
      annualBvgContribution:
          annualBvgContribution ?? existing.annualBvgContribution,
      annualSupraContribution:
          annualSupraContribution ?? existing.annualSupraContribution,
      isVestedBenefits: isVestedBenefits ?? existing.isVestedBenefits,
    );
    pillar2 = [for (final a in pillar2) a.id == id ? account : a];
    return account;
  }

  @override
  Future<void> deletePillar2Account(String id) async {
    deletedPillar2Ids.add(id);
    pillar2 = pillar2.where((a) => a.id != id).toList();
  }

  @override
  Future<Pillar3aAccountDto> createPillar3aAccount({
    required String providerName,
    required String accountType,
    required int currentBalance,
    int? annualContribution,
    double? interestRateOrReturn,
  }) async {
    lastPillar3aCreate = {
      'providerName': providerName,
      'accountType': accountType,
      'currentBalance': currentBalance,
      'annualContribution': annualContribution,
      'interestRateOrReturn': interestRateOrReturn,
    };
    final account = Pillar3aAccountDto(
      id: 'p3-new',
      providerName: providerName,
      accountType: accountType,
      currentBalance: currentBalance,
      annualContribution: annualContribution,
      interestRateOrReturn: interestRateOrReturn,
    );
    pillar3a = [...pillar3a, account];
    return account;
  }

  @override
  Future<Pillar3aAccountDto> updatePillar3aAccount(
    String id, {
    String? providerName,
    String? accountType,
    int? currentBalance,
    int? annualContribution,
    double? interestRateOrReturn,
  }) async {
    final existing = pillar3a.firstWhere((a) => a.id == id);
    return Pillar3aAccountDto(
      id: id,
      providerName: providerName ?? existing.providerName,
      accountType: accountType ?? existing.accountType,
      currentBalance: currentBalance ?? existing.currentBalance,
      annualContribution: annualContribution ?? existing.annualContribution,
      interestRateOrReturn:
          interestRateOrReturn ?? existing.interestRateOrReturn,
    );
  }

  @override
  Future<void> deletePillar3aAccount(String id) async {
    deletedPillar3aIds.add(id);
    pillar3a = pillar3a.where((a) => a.id != id).toList();
  }
}

void main() {
  late FakeFinancialProfileRepository repository;

  setUp(() {
    repository = FakeFinancialProfileRepository();
  });

  /// Very tall viewport: the whole page is built without scrolling.
  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FinancialProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Enregistrer').last);
    await tester.pumpAndSettle();
  }

  testWidgets('creation (initial 404): empty form, full PUT with '
      'REGISTERED_PARTNERSHIP, PATCH /users/me without null fields', (
    tester,
  ) async {
    repository.base = FakeFinancialProfileRepository._base(
      canton: null,
      birthYear: null,
    );
    await pumpProfile(tester);

    // Creation mode: sections visible, no accounts.
    expect(find.text('Informations personnelles'), findsOneWidget);
    expect(find.text('Situation financière'), findsOneWidget);
    expect(find.text('Aucun compte LPP renseigné'), findsOneWidget);
    expect(find.text('Aucun compte 3a renseigné'), findsOneWidget);

    // Marital status: Partenariat enregistré (contract enum).
    await tester.tap(find.text('Célibataire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partenariat enregistré').last);
    await tester.pumpAndSettle();

    // Gross income in CHF — converted to centimes when sent.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      "95'000",
    );
    await tapSave(tester);

    // Flutter sends the correct enum value (iOS used to emit PARTNERSHIP).
    expect(repository.lastProfileUpsert, {
      'employmentStatus': 'EMPLOYED',
      'maritalStatus': 'REGISTERED_PARTNERSHIP',
      'numberOfChildren': 0,
      'grossAnnualIncome': 9500000,
      'netAnnualIncome': null,
    });
    // Canton/year not entered → null client-side (omitted from the body by the repository).
    expect(repository.lastUserUpdate, {
      'canton': null,
      'birthYear': null,
      'replacementRateGoal': 70,
      'municipality': null,
      'clearMunicipality': false,
    });
    expect(find.text('Profil enregistré'), findsOneWidget);
  });

  testWidgets('edit: fields pre-filled, change sent in centimes', (
    tester,
  ) async {
    repository.base = FakeFinancialProfileRepository._base(
      profile: const FinancialProfileDto(
        id: 'fp-1',
        employmentStatus: 'SELF_EMPLOYED',
        maritalStatus: 'MARRIED',
        numberOfChildren: 2,
        grossAnnualIncome: 8500000,
        netAnnualIncome: 7800000,
      ),
    );
    await pumpProfile(tester);

    // Pre-fill: CHF (no centimes exposed), enums, user.
    expect(find.text('85000'), findsOneWidget);
    expect(find.text('78000'), findsOneWidget);
    expect(find.text('1991'), findsOneWidget);
    expect(find.text('Marié(e)'), findsOneWidget);
    expect(find.text('Indépendant(e)'), findsOneWidget);
    expect(find.text('Vaud (VD)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      "100'000",
    );
    await tapSave(tester);

    expect(repository.lastProfileUpsert!['grossAnnualIncome'], 10000000);
    expect(repository.lastProfileUpsert!['maritalStatus'], 'MARRIED');
    expect(repository.lastProfileUpsert!['numberOfChildren'], 2);
    // Net unchanged: existing value sent back (centimes).
    expect(repository.lastProfileUpsert!['netAnnualIncome'], 7800000);
    expect(repository.lastUserUpdate, {
      'canton': 'VD',
      'birthYear': 1991,
      'replacementRateGoal': 70,
      'municipality': null,
      'clearMunicipality': false,
    });
  });

  testWidgets('validation: invalid amount blocks the save', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      'abc',
    );
    await tapSave(tester);

    expect(find.text('Montant invalide'), findsOneWidget);
    expect(repository.lastProfileUpsert, isNull);
    expect(repository.lastUserUpdate, isNull);
  });

  testWidgets('validation: gross income required (creation mode)', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tapSave(tester);

    expect(find.text('Champ requis'), findsOneWidget);
    expect(repository.lastProfileUpsert, isNull);
  });

  testWidgets('canton: picker filtered without accents, selection saved', (
    tester,
  ) async {
    repository.base = FakeFinancialProfileRepository._base(canton: null);
    await pumpProfile(tester);

    await tester.tap(find.text('Sélectionner'));
    await tester.pumpAndSettle();

    // Accent-insensitive search: 'geneve' finds 'Genève'.
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un canton'),
      'geneve',
    );
    await tester.pumpAndSettle();
    expect(find.text('Genève (GE)'), findsOneWidget);

    await tester.tap(find.text('Genève (GE)'));
    await tester.pumpAndSettle();
    expect(find.text('Genève (GE)'), findsOneWidget);

    // Minimal save: the chosen canton is sent in the PATCH.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      '85000',
    );
    await tapSave(tester);
    expect(repository.lastUserUpdate!['canton'], 'GE');
  });

  testWidgets('municipality: tile visible, selection via the picker sent '
      'in the PATCH', (tester) async {
    repository.municipalities = const [
      MunicipalityInfo(name: 'Échallens', multiplier: 78),
      MunicipalityInfo(name: 'Lausanne', multiplier: 79.5),
      MunicipalityInfo(name: 'Renens', multiplier: 77),
    ];
    await pumpProfile(tester);

    // The Commune tile appears below the canton tile; with no selection →
    // cantonal average shown.
    expect(find.text('Commune'), findsOneWidget);
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);

    await tester.tap(find.text('Commune'));
    await tester.pumpAndSettle();

    // Accent-insensitive search: 'echallens' finds 'Échallens'.
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher une commune'),
      'echallens',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Échallens'));
    await tester.pumpAndSettle();
    expect(find.text('Échallens'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      '85000',
    );
    await tapSave(tester);
    expect(repository.lastUserUpdate!['municipality'], 'Échallens');
    expect(repository.lastUserUpdate!['clearMunicipality'], false);
  });

  testWidgets('municipality: canton change resets the municipality → '
      'explicit null in the PATCH (clearing)', (tester) async {
    repository.base = FakeFinancialProfileRepository._base(
      municipality: 'Lausanne',
    );
    await pumpProfile(tester);

    // Commune pre-filled from the profile.
    expect(find.text('Lausanne'), findsOneWidget);

    // Canton change: the municipality is reset.
    await tester.tap(find.text('Vaud (VD)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genève (GE)'));
    await tester.pumpAndSettle();
    expect(find.text('Lausanne'), findsNothing);
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      '85000',
    );
    await tapSave(tester);
    expect(repository.lastUserUpdate!['canton'], 'GE');
    // A municipality was already saved: the explicit null requests clearing it.
    expect(repository.lastUserUpdate!['municipality'], isNull);
    expect(repository.lastUserUpdate!['clearMunicipality'], true);
  });

  testWidgets('municipality: "cantonal average" option deselects the '
      'pre-filled municipality → explicit null in the PATCH', (tester) async {
    repository.municipalities = const [
      MunicipalityInfo(name: 'Échallens', multiplier: 78),
      MunicipalityInfo(name: 'Lausanne', multiplier: 79.5),
    ];
    repository.base = FakeFinancialProfileRepository._base(
      municipality: 'Lausanne',
    );
    await pumpProfile(tester);

    // Commune pre-filled from the profile.
    expect(find.text('Lausanne'), findsOneWidget);

    // Explicit deselection via the picker's 'cantonal average' option.
    await tester.tap(find.text('Commune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moyenne cantonale (commune non listée)'));
    await tester.pumpAndSettle();
    expect(find.text('Lausanne'), findsNothing);
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      '85000',
    );
    await tapSave(tester);
    expect(repository.lastUserUpdate!['municipality'], isNull);
    expect(repository.lastUserUpdate!['clearMunicipality'], true);
  });

  testWidgets('municipality: without a canton, tile disabled with hint', (
    tester,
  ) async {
    repository.base = FakeFinancialProfileRepository._base(
      canton: null,
      birthYear: null,
    );
    await pumpProfile(tester);

    expect(find.text("Choisissez d'abord un canton"), findsOneWidget);

    // Tile disabled: the picker doesn't open.
    await tester.tap(find.text('Commune'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir une commune'), findsNothing);
  });

  testWidgets('add 3a account: POST with type BANK and balance in centimes', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Ajouter un compte 3a'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau compte 3a'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prestataire'),
      'VIAC',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Solde actuel (CHF)'),
      "10'000",
    );
    await tapSave(tester); // sheet button (last 'Enregistrer')

    expect(repository.lastPillar3aCreate, {
      'providerName': 'VIAC',
      'accountType': 'BANK',
      'currentBalance': 1000000,
      'annualContribution': null,
      'interestRateOrReturn': null,
    });
    expect(find.text('Compte enregistré'), findsOneWidget);
    // The reloaded section shows the new account.
    expect(find.text('VIAC'), findsOneWidget);
    expect(find.textContaining("CHF 10'000.00"), findsOneWidget);
  });

  testWidgets('add 3a account: targeted reload fails after creation '
      '→ success snackbar shown anyway (minor #6)', (tester) async {
    await pumpProfile(tester);

    // The targeted list reload will fail after creation.
    repository.pillar3aFetchError = const NetworkException();

    await tester.tap(find.text('Ajouter un compte 3a'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prestataire'),
      'VIAC',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Solde actuel (CHF)'),
      "10'000",
    );
    await tapSave(tester); // sheet button (last 'Enregistrer')

    // The CRUD succeeded: success shown, no error snackbar.
    expect(repository.lastPillar3aCreate, isNotNull);
    expect(find.text('Compte enregistré'), findsOneWidget);
    expect(find.text('Erreur réseau'), findsNothing);
  });

  testWidgets('add LPP account: collapsible advanced section, amounts '
      'sent in centimes', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Ajouter un compte LPP'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau compte LPP'), findsOneWidget);

    // Advanced section collapsed by default.
    expect(find.text('Salaire assuré (CHF)'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel (CHF)'),
      "15'000",
    );

    // Expands the advanced section and fills in the 3 fields.
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Salaire assuré (CHF)'),
      '80000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Déduction de coordination (CHF)'),
      '26460',
    );
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Cotisation surobligatoire annuelle (CHF)',
      ),
      '1000',
    );
    await tapSave(tester); // sheet button (last 'Enregistrer')

    expect(repository.lastPillar2Create, {
      'providerName': null,
      'currentCapital': 1500000,
      'conversionRate': null,
      'insuredSalary': 8000000,
      'coordinationDeduction': 2646000,
      'annualBvgContribution': null,
      'annualSupraContribution': 100000,
      'isVestedBenefits': false,
    });
    expect(find.text('Compte enregistré'), findsOneWidget);
  });

  testWidgets('edit LPP account: advanced fields pre-filled from the '
      'DTO', (tester) async {
    repository.pillar2 = [
      const Pillar2AccountDto(
        id: 'p2-1',
        providerName: 'Caisse ACME',
        currentCapital: 1500000,
        insuredSalary: 8000000,
        coordinationDeduction: 2646000,
        annualSupraContribution: 100000,
        isVestedBenefits: false,
      ),
    ];
    await pumpProfile(tester);

    await tester.tap(find.text('Caisse ACME'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le compte LPP'), findsOneWidget);

    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    // CHF (no centimes exposed), like the other amounts.
    expect(find.text('80000'), findsOneWidget);
    expect(find.text('26460'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('add LPP account: invalid advanced amount blocks the '
      'save', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Ajouter un compte LPP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel (CHF)'),
      "15'000",
    );
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Salaire assuré (CHF)'),
      '-5',
    );
    await tapSave(tester);

    // Same bound as the Zod schema (amount ≥ 0): blocking validation.
    expect(find.text('Montant invalide'), findsOneWidget);
    expect(repository.lastPillar2Create, isNull);
  });

  testWidgets('add LPP account: negative advanced amount, section '
      'collapsed → blocked client-side, no API call', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Ajouter un compte LPP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel (CHF)'),
      "15'000",
    );
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Salaire assuré (CHF)'),
      '-5',
    );

    // Collapses the section: the invalid field leaves the tree, inline
    // validation is short-circuited — the submit guard takes over.
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    expect(find.text('Salaire assuré (CHF)'), findsNothing);

    await tapSave(tester);

    // No pop → no API call (never a server 400).
    expect(repository.lastPillar2Create, isNull);
    // The section was reopened and the inline error is shown.
    expect(find.text('Montant invalide'), findsOneWidget);
  });

  testWidgets('delete LPP account: confirmation then DELETE', (tester) async {
    repository.pillar2 = [
      const Pillar2AccountDto(
        id: 'p2-1',
        providerName: 'Caisse ACME',
        currentCapital: 1500000,
        isVestedBenefits: false,
      ),
    ];
    await pumpProfile(tester);

    expect(find.text('Caisse ACME'), findsOneWidget);
    expect(find.textContaining("CHF 15'000.00"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce compte ?'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(repository.deletedPillar2Ids, ['p2-1']);
    expect(find.text('Compte supprimé'), findsOneWidget);
    expect(find.text('Aucun compte LPP renseigné'), findsOneWidget);
  });

  testWidgets('network error on load: message + retry', (tester) async {
    repository.baseError = const NetworkException();
    await pumpProfile(tester);

    expect(find.text('Erreur réseau'), findsOneWidget);

    repository.baseError = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Situation financière'), findsOneWidget);
  });

  testWidgets('pop during save: no use of ref after '
      'dispose', (tester) async {
    repository.saveGate = Completer<void>();

    // Route pushed so the screen can be left during the save.
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FinancialProfileScreen(),
                  ),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      '85000',
    );
    // The save is triggered but stays in flight (fake's lock).
    await tester.tap(find.text('Enregistrer').last);
    await tester.pump();

    // Leaves the screen while the PUT is in flight.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // The response arrives after dispose: without the mounted guard,
    // `ref.invalidate` would throw an exception.
    repository.saveGate!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The save did complete successfully on the repository side.
    expect(repository.lastProfileUpsert, isNotNull);
  });
}
