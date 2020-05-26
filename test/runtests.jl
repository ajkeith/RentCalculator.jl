using RentCalculator
using Test

@testset "RentCalculator.jl" begin
    # California example
    params = (800_000.0, # home purchase price (dollars)
                5.0, # time in residence (years)
                3.5, # mortgage rate (percent)
                20.0, # mortgage down payment (percent of purchase price)
                30.0, # mortgage length (years)
                3_600.0, # monthly rent (dollars)
                3_500.0, # rental deposit (dollars)
                0.0, # rent broker's fee (dollars)
                0.5, # rental insurance rate (percent of purchase price)
                4.0, # annual home price appreciation rate (percent)
                2.0, # annual rent rate increase (percent)
                7.0, # annual nominal return on investment (percent)
                2.0, # annual inflation rate (percent)
                1.0, # annual property tax rate (percent)
                33.3, # marginal tax rate (percent)
                24.3, # tax rate on investments (percent)
                100_000.0, # captial gains deduction (dollars)
                3.0, # cost of buying house (percent of purchase price)
                5.0, # cost of selling house (percent of selling price)
                0.5, # annual renovation costs (percent of purchase price)
                0.5, # annual maintenance costs (percent of purchase price)
                0.2, # homeowners insurance (percent of purchase price)
                200.0, # additional monthly utilities compared to renting (dollars)
                400.0, # common fee (dollars)
                20.0, # percent of common fee that is deductible (percent)) 
    # cost output format: (total, initial costs, recurring costs, opportunity costs, net proceeds)
    @test cost(params, option="rent") = (251_705, 3_500, 225_939, 25_766, -3_500)
    @test cost(params, option="buy") = (186_786, 184_000, 253_479, 82_085, 332_778)
end
