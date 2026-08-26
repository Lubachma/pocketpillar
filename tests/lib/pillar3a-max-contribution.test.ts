import { describe, it, expect } from 'vitest';
import { pillar3aMaxContribution } from '../../src/lib/pillar3a-max-contribution.js';

/**
 * 3a cap (OPP3 art. 7, 2026): CHF 7'258 with a 2nd pillar; without a 2nd
 * pillar (self-employed not affiliated to a pension fund), 20% of the net
 * earned income capped at CHF 36'288. All amounts in centimes (CHF * 100).
 */
describe('pillar3aMaxContribution', () => {
  it("returns CHF 7'258 with a 2nd pillar, whatever the income", () => {
    expect(pillar3aMaxContribution(true, 0)).toBe(725_800);
    expect(pillar3aMaxContribution(true, 10_000_000)).toBe(725_800);
    expect(pillar3aMaxContribution(true, 50_000_000)).toBe(725_800);
  });

  it('caps the self-employed at 20% of the income below the legal max', () => {
    // CHF 100'000 income -> 20% = CHF 20'000 (< CHF 36'288).
    expect(pillar3aMaxContribution(false, 10_000_000)).toBe(2_000_000);
    // CHF 50'000 income -> CHF 10'000.
    expect(pillar3aMaxContribution(false, 5_000_000)).toBe(1_000_000);
  });

  it("caps the self-employed at CHF 36'288 once 20% of the income exceeds it", () => {
    // CHF 300'000 income -> 20% = CHF 60'000 -> capped at CHF 36'288.
    expect(pillar3aMaxContribution(false, 30_000_000)).toBe(3_628_800);
    // Boundary: CHF 181'440 income -> 20% = exactly CHF 36'288.
    expect(pillar3aMaxContribution(false, 18_144_000)).toBe(3_628_800);
    // Just below the boundary: CHF 181'439 -> CHF 36'287.80.
    expect(pillar3aMaxContribution(false, 18_143_900)).toBe(3_628_780);
  });

  it('never returns a negative cap', () => {
    expect(pillar3aMaxContribution(false, 0)).toBe(0);
    expect(pillar3aMaxContribution(false, -500_000)).toBe(0);
  });

  it('truncates the 20% to the lower centime (never rounds up the deductible)', () => {
    // CHF 100'000.03 income -> 20% = CHF 20'000.006 -> truncated to CHF 20'000.00
    // (Math.round would give CHF 20'000.01). Parity with the Dart `~/` operator.
    expect(pillar3aMaxContribution(false, 10_000_003)).toBe(2_000_000);
    // CHF 181'440.01 -> 20% = CHF 36'288.002 -> CHF 36'288.00 (just at the cap).
    expect(pillar3aMaxContribution(false, 18_144_001)).toBe(3_628_800);
  });
});
