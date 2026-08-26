import '../../../core/auth/auth_repository.dart';
import '../../../core/notifications/pillar3a_reminder.dart';
import '../../../core/utils/swiss_pension.dart';
import '../data/financial_profile_repository.dart';

/// Loads the contextual 3a reminder context (batch 7 — calendar-based
/// alerts, TODO §5); **null → the generic body is kept**.
///
/// All degradations are silent (graceful fallback): not logged in,
/// profile never filled in (404), no 3a account, network/API error.
/// The remaining amount to pay in is `cap − Σ annualContribution`
/// (clamped ≥ 0); the cap follows OPP3 art. 7: 7'258 with a 2nd pillar —
/// status `EMPLOYED` **or an existing LPP account** (optional LPP for a
/// self-employed person included, batch 12 review) — otherwise
/// min(36'288, 20% of income) based on the **declared net income,
/// falling back to gross** (`pillar3aIncomeBaseFor`). Days are counted
/// from the reminder's **delivery date** (next Nov 1st), not from the
/// scheduling instant — deterministic: 60 (batch 7 review).
Future<Pillar3aReminderContext?> loadPillar3aReminderContext({
  required AuthRepository auth,
  required FinancialProfileRepository profiles,
  DateTime Function()? now,
}) async {
  if (auth.currentSession == null) return null;
  try {
    final (accounts, pillar2Accounts, profile) = await (
      profiles.fetchPillar3aAccounts(),
      profiles.fetchPillar2Accounts(),
      profiles.fetchProfileOrNull(),
    ).wait;
    if (profile == null || accounts.isEmpty) return null;
    return Pillar3aReminderContext(
      remainingCentimes: pillar3aRemainingCentimes(
        hasSecondPillar: hasSecondPillarFor(
          employmentStatus: profile.employmentStatus,
          hasPillar2Account: pillar2Accounts.isNotEmpty,
        ),
        incomeCentimes: pillar3aIncomeBaseFor(
          grossAnnualIncomeCentimes: profile.grossAnnualIncome,
          netAnnualIncomeCentimes: profile.netAnnualIncome,
        ),
        annualContributions: [
          for (final account in accounts) account.annualContribution,
        ],
      ),
      daysUntilYearEnd: daysUntilYearEnd(
        pillar3aReminderDeliveryDate((now ?? DateTime.now)()),
      ),
    );
  } on Object {
    return null;
  }
}
