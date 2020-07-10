module RentCalculator

using Parameters

@with_kw struct Param
    buy_price = 800_000.0 # home purchase price (dollars)
    stay = 5.0 # time in residence (years)
    mortgage_rate = 3.5 # mortgage rate (percent)
    mortgage_down = 20.0 # mortgage down payment (percent of purchase price)
    mortgage_length = 30.0 # mortgage length (years)
    rent_monthly = 3_600.0 # monthly rent (dollars)
    rent_deposit = 3_500.0 # rental deposit (dollars)
    rent_broker = 0.0 # rent broker's fee (dollars)
    rent_insurance = 0.5 # rental insurance rate (percent of purchase price)
    price_rate = 4.0 # annual home price appreciation rate (percent)
    rent_rate = 2.0 # annual rent rate increase (percent)
    market_rate = 7.0 # annual nominal return on investment (percent)
    inflation_rate = 2.0 # annual inflation rate (percent)
    tax_property = 1.0 # annual property tax rate (percent)
    tax_marginal = 33.3 # marginal tax rate (percent)
    tax_investment = 24.3 # tax rate on investments (percent)
    tax_capitalgains = 100_000.0 # captial gains deduction (dollars)
    buy_closing = 3.0 # cost of buying house (percent of purchase price)
    buy_selling = 5.0 # cost of selling house (percent of selling price)
    buy_renovation = 0.5 # annual renovation costs (percent of purchase price)
    buy_maintenance = 0.5 # annual maintenance costs (percent of purchase price)
    buy_insurance = 0.2 # homeowners insurance (percent of purchase price)
    buy_utilities = 200.0 # additional monthly utilities compared to renting (dollars)
    buy_common = 400.0 # common fee (dollars)
    buy_deductible = 20.0 # percent of common fee that is deductible (percent)
end 

"""
    interest(p, horizon)

Calculate yearly interest on a mortgage loan with details specified in Param `p` for time `horizon`. 

# Examples
```julia-repl
julia> interest(Param(), 30)
[long output]
```
"""
function interest(p::Param, horizon)
    interest_cumulative = zeros(horizon)
    interest_gains = zeros(horizon)
    return true
end


end

#