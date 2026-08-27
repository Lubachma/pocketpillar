# Fiscal Accuracy

A pension app is only as credible as its numbers. This document explains
where every tax and pension figure in PocketPillar comes from, how it is
validated against official Swiss sources, what is approximated (and why),
and how the data is kept current. It reflects a full audit of the
calculation engine conducted in August 2026 against the official 2026
sources (FSIO/OFAS, FTA/ESTV, and the BVG/LPP, AHV/LAVS, DBG/LIFD acts).

> PocketPillar provides information and indicative simulations — not
> investment advice within the meaning of the Swiss Financial Services Act
> (FinSA/LSFin). Every simulation screen in the app carries this notice.

## Method: anchored to the official FTA calculator

Cantonal and communal income taxes in Switzerland do not follow one
formula — each of the 26 cantons has its own tariff, multiplied by a
cantonal and a communal coefficient. Instead of approximating them,
PocketPillar **samples the official calculator of the Swiss Federal Tax
Administration (FTA/ESTV)**:

- **10,686 calls** to the official calculator API
  (<https://swisstaxcalculator.estv.admin.ch>) produced per-canton tax
  tables for single and married taxpayers on a **CHF 1,000 income grid up
  to CHF 150,000** (coarser steps above)
  (`src/lib/constants/cantonal-income-tables.ts`).
- Values between grid points are **linearly interpolated** — the error is
  bounded to a few francs.
- The sampled tables encode the *simple* cantonal tax at the cantonal
  capital; the app then applies the **real cantonal multiplier** and the
  **real communal multiplier** of the user's municipality
  (`src/lib/constants/communal-multipliers.ts`, ~100 largest
  municipalities, sourced from the ESTV data set, tax year 2026).
- **Capital-withdrawal taxes** (pillar 2/3a lump sums) use the FTA's real
  per-canton tables with a distinct married tariff
  (`src/lib/constants/capital-withdrawal-tables.ts`) — including the
  federal art. 38 DBG/LIFD one-fifth-of-tariff rule — replacing the naive
  "divide by 5" heuristic that flattens real cantonal differences (the
  engine's own ZH/VD spread on a CHF 500k withdrawal is ≈ CHF 6,900).
- The **federal direct tax (IFD)** uses the official 2026 tariff
  (ESTV circular / Rundschreiben no. 215), for both single and married
  scales.

## Validation: to the franc, reproducible

- Anchor values reproduce the official FTA calculator **to the franc** on
  the federal and ZH anchors — e.g. federal tax for a single taxpayer at
  CHF 100,000: CHF 2,684; married at CHF 100,000 / 200,000:
  CHF 1,816 / 11,880 — and within a CHF 20 sampling tolerance on the
  GE/VD cantonal anchors (currently also exact).
- The anchors are re-checkable with one command (no write, exit 0 = no
  drift against the sampled tables):

  ```bash
  node scripts/regen-cantonal-tax-tables.mjs --check
  ```

- The backend test suite encodes official 2026 values as expected results
  (`npm test` — the calculation functions are pure and run without a
  database), so any accidental change to a legal constant fails CI.
- Communal multipliers have their own regeneration + drift check:
  `node scripts/regen-communal-multipliers.mjs --year 2026 --check`.

## Legal parameters in force (2026)

Only rules that are **actually in force** are modeled. The August 2026
audit notably removed a modeling of the "BVG/LPP reform 2024", which was
**rejected by popular vote on 22 September 2024** and never became law —
a mistake several calculators still make. Current parameters:

| Parameter | Value | Source |
|---|---|---|
| BVG/LPP entry threshold | CHF 22,680 | FSIO/OFAS bulletin no. 167 (16.12.2025) |
| Coordination deduction (fixed) | CHF 26,460 (7/8 of max AHV pension) | idem |
| Coordinated salary | CHF 3,780 – 64,260 | idem |
| Retirement credits | 7 / 10 / 15 / 18 % (4 age brackets) | BVG/LPP art. 16 |
| Minimum conversion rate | 6.8 % | BVG/LPP art. 14 |
| AHV/AVS max pension | CHF 30,240/year (2,520/month) | 2025–2026 values, unchanged on 1.1.2026 |
| AHV/AVS min pension | CHF 15,120/year | idem |
| Married couple cap | 150 % = CHF 45,360/year | idem |
| Pillar 3a max deduction (employed) | CHF 7,258 | 2026 value |
| Federal tax tariff | official 2026 | ESTV circular no. 215 |

**Process rule** (learned the hard way): a reform is only integrated once
it is **actually in force** — the FSIO December bulletin is authoritative,
not press coverage of upcoming votes.

## Practitioner review (August 2026)

A working insurance/pension advisor reviewed the app against his
professional reference material (year-by-year min/max social-insurance
tables, the official FSIO "Amounts valid from 1 January 2026" leaflet,
and real advisory-tool outputs) and tested the live demo hands-on.

**Constants: full match.** Every statutory figure above matched his
tables — AHV min/max and couple cap, BVG threshold/coordination/
coordinated-salary bounds, 3a maxima, and the 1/5-rate rule for capital
withdrawals (DBG/LIFD art. 38).

**Findings from his live test — all fixed:**

- **Retirement credits were frozen at the current age's rate** across the
  whole LPP minimum projection (a 30-year-old was projected at 7 % for 35
  years instead of 7→10→15→18 %), understating the legal-minimum capital
  by up to ~1.8× for young profiles. The projection now steps through the
  age brackets year by year (`lpp-gap.ts`).
- **Couple display**: per-spouse AVS rows showed two uncapped pensions
  next to a correctly capped total. The API now returns a per-spouse view
  with the cap allocated pro rata (LAVS art. 35 al. 3 — two max pensions
  → CHF 2,047.50/month each), and the app displays it.
- **Conversion rate**: 6.8 % is the legal minimum on the **mandatory**
  part only; funds usually convert supra-mandatory capital at ~5–6 %. The
  certificate rate can now be entered per spouse, and the 6.8 % default
  carries an explicit warning.
- **Capital-withdrawal tax**: projected 3a capital is now shown with the
  estimated withdrawal tax (official FTA 2026 tables) instead of gross
  only; the couple withdrawal plan already priced it per step.
- A stale UI label still said "simplified schedules" — the tax comparison
  has used the official sampled FTA tables since the August 2026 audit.

**Deliberate divergences from his tables** (kept, with reasons):

- **3a maximum CHF 7,258**: his sheet derives 7,257.60 from the 8 %
  formula; the official FSIO leaflet publishes **7,258**, which is what
  the law applies (and what we use).
- **Retirement credits total 500 %** over a 25→65 career (art. 16 BVG:
  ten years per bracket); some practitioner tables count 55–65 as eleven
  years (518 %). A dedicated test locks the 500 % sum.
- **13th AHV pension**: absent from his year tables; we model it as
  ×13/12 from 2026 — exactly the official leaflet's wording ("the 13th
  pension equals one twelfth of the pensions actually paid in the year").
  The AHV/AVS pension is annualized over **13** payments, IV/AI stays at 12.

## AHV/AVS pension estimation

The default estimate projects contribution years **to retirement**
(`min(retirementAge − 20, 44)`) rather than counting only years already
contributed — the latter under-estimates a 30-year-old's pension by 2–4×.
The official scale 44 is approximated by linear interpolation between the
minimum and maximum pensions (see approximations below).

## Documented approximations

Honesty about limits is part of accuracy. These are known, deliberate, and
non-blocking; the app words all results as estimates:

- **AHV scale 44**: linear interpolation instead of the official CHF 50
  step table — typical deviation < 3 %; a real pension depends on the
  individual contribution record anyway.
- **Gross income as a proxy for taxable income** (individual deductions
  are unknown) — 3a tax savings are slightly overestimated at high
  incomes; results are labeled indicative.
- **Church tax**: per-canton factor on (cantonal + communal), sampled for
  the Reformed confession.
- **Capital-withdrawal tax outside the cantonal capital**: adjusted by the
  ratio of communal multipliers (capital vs income coefficients differ
  slightly in a few cantons).
- **Women born 1961–1963** (AHV 21 transition, reference age 64.25–64.75):
  not modeled — the app does not ask for gender and uses 65 for everyone;
  transitory deviation ≤ 1 year.
- **Divorce — AHV impact**: flat estimate (~2 % of the max pension per
  marriage year, split) — the real rule (income splitting + child-raising
  credits) requires both spouses' AHV statements.
- **Child-raising / assistance credits and splitting**: the AHV estimate
  works from income and projected contribution years only; child-raising
  credits (BTE), assistance credits (BTA) and marital income splitting are
  not modeled (the profile captures the number of children but does not
  yet feed it into the AHV estimate).
- **Single conversion rate on the full LPP capital**: the entered (or
  default 6.8 %) rate converts the whole projected capital; the split
  between mandatory (6.8 % guaranteed) and supra-mandatory capital
  (fund-specific, usually lower) is not modeled — the UI says so and asks
  for the certificate rate.
- **Couple AVS cap phasing — now modeled**: the couple simulation returns
  a dated timeline (one phase per retirement): with an age gap the
  earlier-retired spouse draws a full pension until the second retirement,
  and the pro-rata cap applies only from then on (LAVS art. 35 — the
  practitioner's "full pension for about a year, then capped"). The
  headline combined figures still describe the cruising phase.
- **Incomplete careers** (arrival in Switzerland, contribution gaps): only
  representable through the projected contribution years — the estimate
  assumes an uninterrupted career from age 20.
- **Pension-score benchmarks**: the age-bracket "averages" shown next to
  the /100 score are indicative orders of magnitude — a dedicated source
  hunt (August 2026) confirmed that no citable per-age-bracket balance
  statistics exist in Switzerland (the Swisscanto study surveys funds,
  not balances per insured — verified in its 2024 and 2025 editions; the
  FSO publishes age classes as headcounts only, and states itself that
  no central 3a database exists). Official reference points used as
  sanity bounds: ~CHF 123,700 average vested capital per active insured,
  all ages (FSO pension-fund statistics 2023) and the FSO new-pensions
  statistics at-retirement medians (2nd pillar CHF 122,917 in 2023;
  3a CHF 45,869 in 2022). The in-app help sheet labels the comparison
  as indicative. The score itself and every projected amount follow the
  legal parameters above.
- **Inflation/indexation**: projections are in constant nominal francs.

## Annual update process

Every tax year (documented in the private ops runbook, owner: the
maintainer):

1. Regenerate the cantonal tables and communal multipliers from the
   official sources (`regen-cantonal-tax-tables.mjs`,
   `regen-communal-multipliers.mjs`).
2. Update legal constants (BVG/AHV/3a/IFD) from the FSIO December bulletin
   and the ESTV circular; only rules in force. Cross-check against the
   FSIO "Amounts valid from 1 January" leaflet and independent
   practitioner tables (AHV figures change again in 2027).
3. Run the anchor checks (`--check`) and the full test suite — the
   expected values in tests are the official figures.

## Sources

- FTA/ESTV official tax calculator — <https://swisstaxcalculator.estv.admin.ch>
- ESTV circular (Rundschreiben) no. 215 — 2026 federal tariff
- FSIO/OFAS bulletin no. 167 (16.12.2025) — 2026 BVG/AHV parameters
- BVG/LPP, AHV/LAVS, DBG/LIFD — <https://www.fedlex.admin.ch>
- ESTV communal/cantonal multiplier data set (mirrored at
  <https://github.com/devbrains-com/swisstaxcalculator>)
