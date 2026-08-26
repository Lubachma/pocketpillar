import { t } from '../../../lib/i18n/index.js';
import type { RecommendationRule } from '../recommendation.types.js';

const MIN_FEE_DIFFERENCE = 0.15;
const fmtChf = (centimes: number) => (centimes / 100).toLocaleString('fr-CH');

// Free-text account provider ("viac ") must match the catalogue entry ("VIAC").
const normalizeProviderName = (name: string) => name.trim().toLowerCase();

export const providerSwitchRule: RecommendationRule = (input) => {
  const { locale, pillar3aAccounts, availableProducts } = input;
  const yearsToRetirement = input.retirementAge - input.currentAge;

  if (pillar3aAccounts.length === 0 || availableProducts.length === 0) return null;

  const mainAccount = pillar3aAccounts.reduce((best, a) =>
    a.currentBalance > best.currentBalance ? a : best,
  );

  const currentRate = mainAccount.interestRateOrReturn ?? 1.0;

  // The current fee comes from the product matching the account's provider —
  // never invented. No match in the catalogue -> no recommendation.
  const currentProduct = availableProducts.find(
    (p) =>
      normalizeProviderName(p.providerName) === normalizeProviderName(mainAccount.providerName),
  );
  if (!currentProduct) return null;
  const currentFee = currentProduct.allInFeePercent;

  const bestProduct = availableProducts.reduce((best, p) =>
    p.allInFeePercent < best.allInFeePercent ? p : best,
  );

  const feeDelta = currentFee - bestProduct.allInFeePercent;

  if (feeDelta < MIN_FEE_DIFFERENCE) return null;

  const annualSaving = Math.round((mainAccount.currentBalance * feeDelta) / 100);
  let lifetimeImpact = 0;
  let capital = mainAccount.currentBalance;
  for (let i = 0; i < yearsToRetirement; i++) {
    lifetimeImpact += Math.round((capital * feeDelta) / 100);
    capital = Math.round(capital * (1 + currentRate / 100));
  }

  return {
    type: 'PROVIDER_SWITCH',
    priority: 'MEDIUM',
    title: t(locale, 'rec.provider_switch.title'),
    description: t(locale, 'rec.provider_switch.description', {
      provider: bestProduct.providerName,
      product: bestProduct.productName,
      newFee: bestProduct.allInFeePercent.toString(),
      oldFee: currentFee.toFixed(2),
      balance: fmtChf(mainAccount.currentBalance),
      saving: fmtChf(annualSaving),
    }),
    estimatedAnnualImpact: annualSaving,
    estimatedLifetimeImpact: lifetimeImpact,
    details: {
      currentProvider: mainAccount.providerName,
      suggestedProvider: bestProduct.providerName,
      suggestedProduct: bestProduct.productName,
      feeDelta,
      currentBalance: mainAccount.currentBalance,
    },
  };
};
