module RentCalculator

using Crayons
using Parameters
using PrettyTables
using Printf

export Param, mortgage_payment, mortgage_balance, interest, cost, compare

# ─────────────────────────────────────────────────────────────────────────────
# Parameter struct
# ─────────────────────────────────────────────────────────────────────────────

"""
    Param

All financial parameters needed for a rent-vs-buy analysis.

# Fields
- `buy_price`        : home purchase price (dollars)
- `stay`             : time in residence (years)
- `mortgage_rate`    : mortgage interest rate (percent)
- `mortgage_down`    : down payment (percent of purchase price)
- `mortgage_length`  : mortgage term (years)
- `rent_monthly`     : monthly rent (dollars)
- `rent_deposit`     : security deposit (dollars)
- `rent_broker`      : broker's fee (dollars)
- `rent_insurance`   : renters insurance (percent of annual rent)
- `price_rate`       : annual home price appreciation (percent)
- `rent_rate`        : annual rent increase (percent)
- `market_rate`      : annual nominal market return (percent)
- `inflation_rate`   : annual inflation rate (percent)
- `tax_property`     : annual property tax rate (percent of home value)
- `tax_marginal`     : marginal income tax rate (percent)
- `tax_investment`   : capital gains / investment income tax rate (percent)
- `tax_capitalgains` : capital gains exclusion on home sale (dollars)
- `buy_closing`      : buying transaction costs (percent of purchase price)
- `buy_selling`      : selling transaction costs (percent of selling price)
- `buy_renovation`   : annual renovation costs (percent of purchase price)
- `buy_maintenance`  : annual maintenance costs (percent of purchase price)
- `buy_insurance`    : homeowners insurance (percent of purchase price)
- `buy_utilities`    : extra monthly utilities vs. renting (dollars)
- `buy_common`       : monthly HOA / common fee (dollars)
- `buy_deductible`   : deductible portion of common fee (percent)
"""
@with_kw struct Param
    buy_price::Float64        = 800_000.0  # home purchase price (dollars)
    stay::Float64             = 5.0        # time in residence (years)
    mortgage_rate::Float64    = 3.5        # mortgage interest rate (percent)
    mortgage_down::Float64    = 20.0       # down payment (percent of purchase price)
    mortgage_length::Float64  = 30.0       # mortgage term (years)
    rent_monthly::Float64     = 3_600.0    # monthly rent (dollars)
    rent_deposit::Float64     = 3_500.0    # security deposit (dollars)
    rent_broker::Float64      = 0.0        # broker's fee (dollars)
    rent_insurance::Float64   = 0.5        # renters insurance (percent of annual rent)
    price_rate::Float64       = 4.0        # annual home price appreciation (percent)
    rent_rate::Float64        = 2.0        # annual rent increase (percent)
    market_rate::Float64      = 7.0        # annual nominal market return (percent)
    inflation_rate::Float64   = 2.0        # annual inflation rate (percent)
    tax_property::Float64     = 1.0        # annual property tax (percent of home value)
    tax_marginal::Float64     = 33.3       # marginal income tax rate (percent)
    tax_investment::Float64   = 24.3       # investment / capital gains tax rate (percent)
    tax_capitalgains::Float64 = 100_000.0  # capital gains exclusion on home sale (dollars)
    buy_closing::Float64      = 3.0        # buying transaction costs (percent of purchase price)
    buy_selling::Float64      = 5.0        # selling transaction costs (percent of selling price)
    buy_renovation::Float64   = 0.5        # annual renovation costs (percent of purchase price)
    buy_maintenance::Float64  = 0.5        # annual maintenance costs (percent of purchase price)
    buy_insurance::Float64    = 0.2        # homeowners insurance (percent of purchase price)
    buy_utilities::Float64    = 200.0      # extra monthly utilities vs. renting (dollars)
    buy_common::Float64       = 400.0      # monthly HOA / common fee (dollars)
    buy_deductible::Float64   = 20.0       # deductible portion of common fee (percent)
end

# ─────────────────────────────────────────────────────────────────────────────
# Mortgage helpers
# ─────────────────────────────────────────────────────────────────────────────

"""
    mortgage_payment(p::Param) -> Float64

Return the fixed monthly mortgage payment using the standard annuity formula.

The monthly payment ``M`` satisfies:

```math
M = L \\cdot \\frac{r(1+r)^n}{(1+r)^n - 1}
```

where ``L`` is the loan amount, ``r`` is the monthly interest rate, and ``n``
is the total number of monthly payments.
"""
function mortgage_payment(p::Param)
    L = p.buy_price * (1.0 - p.mortgage_down / 100.0)
    r = p.mortgage_rate / 100.0 / 12.0
    n = round(Int, p.mortgage_length * 12)
    r ≈ 0.0 && return L / n
    return L * r * (1.0 + r)^n / ((1.0 + r)^n - 1.0)
end

"""
    mortgage_balance(p::Param, months::Int) -> Float64

Return the outstanding principal balance after `months` monthly payments.

Uses the closed-form amortisation formula:

```math
B_t = L(1+r)^t - M\\frac{(1+r)^t - 1}{r}
```
"""
function mortgage_balance(p::Param, months::Int)
    L = p.buy_price * (1.0 - p.mortgage_down / 100.0)
    r = p.mortgage_rate / 100.0 / 12.0
    n = round(Int, p.mortgage_length * 12)
    months >= n && return 0.0
    M = mortgage_payment(p)
    r ≈ 0.0 && return L * (1.0 - months / n)
    return L * (1.0 + r)^months - M * ((1.0 + r)^months - 1.0) / r
end

# ─────────────────────────────────────────────────────────────────────────────
# Interest schedule
# ─────────────────────────────────────────────────────────────────────────────

"""
    interest(p::Param, horizon) -> NamedTuple

Calculate the annual mortgage interest paid for each year up to `horizon`.

Returns a named tuple with:
- `annual`     : interest paid in each year (vector, length = horizon)
- `cumulative` : running total of interest paid (vector, length = horizon)

# Examples
```julia-repl
julia> p = Param();
julia> r = interest(p, 5);
julia> r.annual        # interest paid in years 1–5
julia> r.cumulative    # cumulative interest through year 5
```
"""
function interest(p::Param, horizon)
    n_years = round(Int, min(horizon, p.mortgage_length))
    r       = p.mortgage_rate / 100.0 / 12.0
    annual  = zeros(Float64, n_years)

    for year in 1:n_years
        for month in 1:12
            month_num = (year - 1) * 12 + month
            balance   = mortgage_balance(p, month_num - 1)
            annual[year] += balance * r
        end
    end

    return (annual = annual, cumulative = cumsum(annual))
end

# ─────────────────────────────────────────────────────────────────────────────
# Internal cost helpers
# ─────────────────────────────────────────────────────────────────────────────

# After-tax annual investment return rate
_after_tax_rate(p::Param) = (p.market_rate / 100.0) * (1.0 - p.tax_investment / 100.0)

"""
Compute opportunity cost of a series of cash outflows.

Each dollar spent on housing is a dollar that cannot be invested.  For an
initial lump sum paid at time 0, and annual recurring payments paid at the
start of each year, the forgone after-tax compound return is:

    OC = initial × ((1+r)^stay - 1)
       + Σ_{t=1}^{stay-1} payment_t × ((1+r)^(stay-t) - 1)

where `r` is the after-tax investment return rate.
"""
function _opportunity_cost(initial::Float64,
                            annual_payments::Vector{Float64},
                            p::Param)
    r  = _after_tax_rate(p)
    oc = initial * ((1.0 + r)^p.stay - 1.0)
    for (t, pmt) in enumerate(annual_payments)
        remaining = p.stay - t
        remaining > 0 && (oc += pmt * ((1.0 + r)^remaining - 1.0))
    end
    return oc
end

# ─────────────────────────────────────────────────────────────────────────────
# Renting cost breakdown
# ─────────────────────────────────────────────────────────────────────────────

function _rent_cost(p::Param)
    n_years = round(Int, p.stay)

    # ── initial outlay ────────────────────────────────────────────────────────
    initial = p.rent_deposit + p.rent_broker

    # ── annual recurring costs (rent + renters insurance, both grow with rent) ─
    annual_recurring = [
        p.rent_monthly * 12.0 * (1.0 + p.rent_rate / 100.0)^(t - 1) *
        (1.0 + p.rent_insurance / 100.0)
        for t in 1:n_years
    ]
    recurring = sum(annual_recurring)

    # ── net proceeds at end: security deposit returned ────────────────────────
    net_proceeds = p.rent_deposit

    # ── opportunity cost: forgone investment returns on every dollar spent ─────
    opportunity = _opportunity_cost(initial, annual_recurring, p)

    total = initial + recurring + opportunity - net_proceeds

    return (
        total        = round(Int, total),
        initial      = round(Int, initial),
        recurring    = round(Int, recurring),
        opportunity  = round(Int, opportunity),
        net_proceeds = round(Int, net_proceeds),
    )
end

# ─────────────────────────────────────────────────────────────────────────────
# Buying cost breakdown
# ─────────────────────────────────────────────────────────────────────────────

function _buy_cost(p::Param)
    n_years = round(Int, p.stay)

    # ── initial outlay: down payment + closing costs ──────────────────────────
    initial = p.buy_price * (p.mortgage_down + p.buy_closing) / 100.0

    # ── mortgage schedule ─────────────────────────────────────────────────────
    M   = mortgage_payment(p)
    int = interest(p, n_years)

    # ── annual recurring costs (net of tax deductions) ────────────────────────
    annual_recurring = Float64[]
    for t in 1:n_years
        gross = (M * 12.0                                          # mortgage P+I
               + p.buy_price * p.tax_property    / 100.0          # property tax
               + p.buy_price * p.buy_maintenance / 100.0          # maintenance
               + p.buy_price * p.buy_renovation  / 100.0          # renovation
               + p.buy_price * p.buy_insurance   / 100.0          # homeowners insurance
               + p.buy_utilities * 12.0                            # extra utilities
               + p.buy_common * 12.0)                              # HOA / common fee

        # Tax deductions reduce effective cost:
        #   • mortgage interest (fully deductible up to loan limit)
        #   • property tax
        #   • deductible fraction of HOA fee
        tax_savings = (
            int.annual[t]          * (p.tax_marginal / 100.0)
          + p.buy_price * p.tax_property / 100.0 * (p.tax_marginal / 100.0)
          + p.buy_common * 12.0 * (p.buy_deductible / 100.0) * (p.tax_marginal / 100.0)
        )

        push!(annual_recurring, gross - tax_savings)
    end
    recurring = sum(annual_recurring)

    # ── net proceeds from selling the home ────────────────────────────────────
    sell_price        = p.buy_price * (1.0 + p.price_rate / 100.0)^p.stay
    selling_costs     = sell_price * p.buy_selling / 100.0
    remaining_balance = mortgage_balance(p, n_years * 12)
    capital_gain      = sell_price - p.buy_price
    taxable_gain      = max(0.0, capital_gain - p.tax_capitalgains)
    cap_gains_tax     = taxable_gain * p.tax_investment / 100.0
    net_proceeds      = sell_price - selling_costs - remaining_balance - cap_gains_tax

    # ── opportunity cost: forgone returns on capital tied up in housing ────────
    opportunity = _opportunity_cost(initial, annual_recurring, p)

    total = initial + recurring + opportunity - net_proceeds

    return (
        total        = round(Int, total),
        initial      = round(Int, initial),
        recurring    = round(Int, recurring),
        opportunity  = round(Int, opportunity),
        net_proceeds = round(Int, net_proceeds),
    )
end

# ─────────────────────────────────────────────────────────────────────────────
# Public cost API
# ─────────────────────────────────────────────────────────────────────────────

"""
    cost(p::Param; option::String = "buy") -> NamedTuple

Compute the total cost of renting or buying over the stay period.

# Arguments
- `p`      : model parameters (see [`Param`](@ref))
- `option` : `"rent"` or `"buy"`

# Returns
A named tuple with integer-rounded dollar values:
| Field         | Meaning                                               |
|:------------- |:----------------------------------------------------- |
| `total`       | net cost of this option over the stay period          |
| `initial`     | upfront outlays (deposit / down payment + closing)    |
| `recurring`   | sum of annual housing costs (net of tax deductions)   |
| `opportunity` | forgone after-tax investment returns on cash spent    |
| `net_proceeds`| money received at the end (deposit back / home sale)  |

The accounting identity is:  `total = initial + recurring + opportunity − net_proceeds`

# Examples
```julia-repl
julia> p = Param();
julia> cost(p, option = "rent")
julia> cost(p, option = "buy")
```
"""
function cost(p::Param; option::String = "buy")
    option == "rent" && return _rent_cost(p)
    option == "buy"  && return _buy_cost(p)
    error("option must be \"rent\" or \"buy\", got \"$(option)\"")
end

# ─────────────────────────────────────────────────────────────────────────────
# Pretty-printed comparison table
# ─────────────────────────────────────────────────────────────────────────────

"""
    compare(p::Param = Param())

Print a polished side-by-side rent-vs-buy cost comparison to the terminal.

# Example
```julia-repl
julia> compare()              # default California parameters
julia> compare(Param(stay=10, buy_price=600_000.0))
```
"""
function compare(p::Param = Param())
    r = cost(p; option = "rent")
    b = cost(p; option = "buy")

    fmt(x) = @sprintf("\$%s", _commify(x))

    rows = [
        "Initial costs"     fmt(r.initial)      fmt(b.initial)
        "Recurring costs"   fmt(r.recurring)    fmt(b.recurring)
        "Opportunity costs" fmt(r.opportunity)  fmt(b.opportunity)
        "Net proceeds"      fmt(r.net_proceeds) fmt(b.net_proceeds)
        "Net total cost"    fmt(r.total)        fmt(b.total)
    ]

    hl_total = TextHighlighter(
        (_, i, _) -> i == size(rows, 1),
        crayon"bold cyan",
    )
    hl_cheaper = if r.total <= b.total
        TextHighlighter(
            (_, i, j) -> i == size(rows, 1) && j == 2,
            crayon"bold green",
        )
    else
        TextHighlighter(
            (_, i, j) -> i == size(rows, 1) && j == 3,
            crayon"bold green",
        )
    end

    style = TextTableStyle(
        column_label = crayon"bold white",
        table_border = crayon"dark_gray",
    )

    println()
    println("  ┌─ Rent vs. Buy Analysis ─────────────────────────────┐")
    @printf("  │  Stay: %g yr  │  Home: \$%s  │  Rate: %.1f%%  │\n",
            p.stay, _commify(round(Int, p.buy_price)), p.mortgage_rate)
    println("  └─────────────────────────────────────────────────────┘")
    println()

    pretty_table(
        rows;
        column_labels = ["", "Rent", "Buy"],
        alignment     = [:l, :r, :r],
        highlighters  = [hl_total, hl_cheaper],
        style         = style,
    )

    verdict = r.total <= b.total ? "renting" : "buying"
    savings = abs(r.total - b.total)
    println()
    @printf("  💡  Over %g years, %-7s saves ~\$%s.\n\n",
            p.stay, verdict, _commify(savings))
end

# Format an integer with comma thousands separators
function _commify(n::Integer)
    s   = string(abs(n))
    out = IOBuffer()
    for (i, c) in enumerate(reverse(s))
        i > 1 && (i - 1) % 3 == 0 && write(out, ',')
        write(out, c)
    end
    str = String(take!(out))
    result = String(reverse(collect(str)))
    n < 0 && return "-" * result
    return result
end

end # module RentCalculator