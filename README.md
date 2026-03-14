# RentCalculator.jl

[![Build Status](https://github.com/ajkeith/RentCalculator.jl/workflows/CI/badge.svg)](https://github.com/ajkeith/RentCalculator.jl/actions)
[![Coverage](https://codecov.io/gh/ajkeith/RentCalculator.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ajkeith/RentCalculator.jl)

A Julia package for quantitative **rent-vs-buy** analysis.

It computes the full cost of each option — including upfront outlays, ongoing
housing costs, tax deductions, home-sale proceeds, and the **opportunity cost**
of capital tied up in housing — so you can make an apples-to-apples comparison.

---

## Quick start

```julia
using RentCalculator

# Use the built-in California defaults …
compare()

# … or customise every parameter
p = Param(
    buy_price     = 750_000.0,  # home purchase price ($)
    stay          = 7.0,         # years you plan to live there
    mortgage_rate = 6.5,         # mortgage interest rate (%)
    rent_monthly  = 3_200.0,     # monthly rent ($)
)
compare(p)
```

### Example output

```
  ┌─ Rent vs. Buy Analysis ─────────────────────────────┐
  │  Stay: 5 yr  │  Home: $800,000  │  Rate: 3.5%  │
  └─────────────────────────────────────────────────────┘

┌───────────────────┬──────────┬──────────┐
│                   │     Rent │      Buy │
├───────────────────┼──────────┼──────────┤
│ Initial costs     │   $3,500 │ $184,000 │
│ Recurring costs   │ $225,939 │ $246,052 │
│ Opportunity costs │  $25,766 │  $81,606 │
│ Net proceeds      │   $3,500 │ $332,778 │
│ Net total cost    │ $251,705 │ $178,881 │
└───────────────────┴──────────┴──────────┘

  💡  Over 5 years, buying  saves ~$72,824.
```

---

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/ajkeith/RentCalculator.jl")
```

---

## Financial model

### Cost identity

For each option the following accounting identity holds (to within ±\$1 due to
independent integer rounding of each component):

```
total = initial + recurring + opportunity − net_proceeds
```

| Component       | Renting                                   | Buying                                      |
|:--------------- |:----------------------------------------- |:------------------------------------------- |
| **initial**     | security deposit + broker fee             | down payment + closing costs                |
| **recurring**   | rent + renters insurance (both grow at `rent_rate`) | mortgage P+I + property tax + maintenance + renovation + insurance + utilities + HOA, minus tax deductions |
| **opportunity** | forgone after-tax investment returns on every dollar spent | same — captures the cost of capital tied up |
| **net_proceeds**| security deposit returned                 | home sale price − selling costs − remaining mortgage − capital-gains tax |

### Tax deductions (buying)

Three items reduce the effective recurring cost:

1. **Mortgage interest** — fully deductible at `tax_marginal` rate.
2. **Property tax** — deductible at `tax_marginal` rate.
3. **HOA fee** — the `buy_deductible` fraction is deductible at `tax_marginal` rate.

### Opportunity cost

Every dollar spent on housing is a dollar that could instead have been invested
at the after-tax market return:

```
r_net = market_rate × (1 − tax_investment / 100)
```

For a lump sum paid at time 0 and annual recurring payments paid at the start
of each year:

```
OC = initial × ((1 + r_net)^stay − 1)
   + Σ_{t=1}^{stay−1} payment_t × ((1 + r_net)^(stay−t) − 1)
```

### Home-sale proceeds (buying)

```
sell_price    = buy_price × (1 + price_rate/100)^stay
selling_costs = sell_price × buy_selling/100
capital_gain  = sell_price − buy_price
taxable_gain  = max(0, capital_gain − tax_capitalgains)
cap_gains_tax = taxable_gain × tax_investment/100

net_proceeds = sell_price − selling_costs − remaining_balance − cap_gains_tax
```

---

## API reference

### `Param`

All 25 model parameters are bundled in a single `@with_kw` struct with
sensible California-market defaults.

| Parameter          | Default       | Description                                        |
|:------------------ |:------------- |:-------------------------------------------------- |
| `buy_price`        | `800_000`     | Home purchase price ($)                            |
| `stay`             | `5`           | Years in residence                                 |
| `mortgage_rate`    | `3.5`         | Mortgage interest rate (%)                         |
| `mortgage_down`    | `20`          | Down payment (% of purchase price)                 |
| `mortgage_length`  | `30`          | Mortgage term (years)                              |
| `rent_monthly`     | `3_600`       | Monthly rent ($)                                   |
| `rent_deposit`     | `3_500`       | Security deposit ($)                               |
| `rent_broker`      | `0`           | Broker fee ($)                                     |
| `rent_insurance`   | `0.5`         | Renters insurance (% of annual rent)               |
| `price_rate`       | `4`           | Annual home price appreciation (%)                 |
| `rent_rate`        | `2`           | Annual rent increase (%)                           |
| `market_rate`      | `7`           | Annual nominal market return (%)                   |
| `inflation_rate`   | `2`           | Annual inflation rate (%)                          |
| `tax_property`     | `1`           | Annual property tax rate (% of home value)         |
| `tax_marginal`     | `33.3`        | Marginal income tax rate (%)                       |
| `tax_investment`   | `24.3`        | Capital gains / investment income tax rate (%)     |
| `tax_capitalgains` | `100_000`     | Capital gains exclusion on home sale ($)           |
| `buy_closing`      | `3`           | Buying transaction costs (% of purchase price)     |
| `buy_selling`      | `5`           | Selling transaction costs (% of selling price)     |
| `buy_renovation`   | `0.5`         | Annual renovation costs (% of purchase price)      |
| `buy_maintenance`  | `0.5`         | Annual maintenance costs (% of purchase price)     |
| `buy_insurance`    | `0.2`         | Homeowners insurance (% of purchase price)         |
| `buy_utilities`    | `200`         | Extra monthly utilities vs. renting ($)            |
| `buy_common`       | `400`         | Monthly HOA / common fee ($)                       |
| `buy_deductible`   | `20`          | Deductible portion of HOA fee (%)                  |

### `cost(p; option)`

```julia
cost(p::Param; option::String = "buy") -> NamedTuple
```

Returns `(total, initial, recurring, opportunity, net_proceeds)` as a named
tuple of `Int` values.  `option` must be `"rent"` or `"buy"`.

### `compare(p)`

```julia
compare(p::Param = Param())
```

Prints a colour-coded terminal table and a one-line verdict.

### `mortgage_payment(p)`

```julia
mortgage_payment(p::Param) -> Float64
```

Fixed monthly mortgage payment using the standard annuity formula.

### `mortgage_balance(p, months)`

```julia
mortgage_balance(p::Param, months::Int) -> Float64
```

Outstanding principal balance after `months` monthly payments.

### `interest(p, horizon)`

```julia
interest(p::Param, horizon) -> NamedTuple{(:annual, :cumulative)}
```

Annual and cumulative mortgage interest paid over `horizon` years.

---

## Requirements

- Julia ≥ 1.9
- [Parameters.jl](https://github.com/mauro3/Parameters.jl)
- [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl)
- [Crayons.jl](https://github.com/KristofferC/Crayons.jl)

---

## License

MIT — see [LICENSE](LICENSE).
