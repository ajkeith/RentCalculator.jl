using RentCalculator
using Test

@testset "RentCalculator.jl" begin

    @testset "Param defaults" begin
        p = Param()
        @test p.buy_price       == 800_000.0
        @test p.mortgage_rate   == 3.5
        @test p.mortgage_down   == 20.0
        @test p.stay            == 5.0
        @test p.rent_monthly    == 3_600.0
    end

    @testset "mortgage_payment" begin
        p = Param()
        M = mortgage_payment(p)
        # Standard annuity formula: L=640000, r=0.035/12, n=360
        @test isapprox(M, 2873.886; atol=0.01)
        # Zero-rate edge case
        p0 = Param(mortgage_rate=0.0)
        @test isapprox(mortgage_payment(p0), 640_000.0 / 360; atol=0.01)
    end

    @testset "mortgage_balance" begin
        p = Param()
        # Balance at month 0 should equal loan amount
        @test isapprox(mortgage_balance(p, 0), 640_000.0; atol=0.01)
        # Balance after full term should be zero
        @test mortgage_balance(p, 360) == 0.0
        # Balance after 5 years (60 payments)
        @test isapprox(mortgage_balance(p, 60), 574_061.27; atol=0.5)
        # Balance decreases monotonically over time
        @test mortgage_balance(p, 60) < mortgage_balance(p, 0)
        @test mortgage_balance(p, 120) < mortgage_balance(p, 60)
    end

    @testset "interest schedule" begin
        p  = Param()
        ir = interest(p, 5)
        # Returns named tuple with annual and cumulative arrays
        @test length(ir.annual)     == 5
        @test length(ir.cumulative) == 5
        # Interest decreases each year as principal is paid down
        @test ir.annual[1] > ir.annual[5]
        # Year-1 interest ≈ loan × annual_rate (rough check)
        @test isapprox(ir.annual[1], 22_204.0; atol=5.0)
        # Cumulative is non-decreasing
        @test all(diff(ir.cumulative) .> 0)
        # Cumulative[5] == sum of annual[1:5]
        @test isapprox(ir.cumulative[5], sum(ir.annual); atol=1e-6)
    end

    @testset "cost — California example" begin
        # Default Param() encodes the California scenario
        p = Param()

        @testset "renting" begin
            r = cost(p; option="rent")
            @test r.initial      == 3_500
            @test r.recurring    == 225_939
            @test r.opportunity  == 25_766
            @test r.net_proceeds == 3_500   # deposit returned
            @test r.total        == 251_705
            # Accounting identity: total = initial + recurring + opportunity - net_proceeds
            @test abs(r.total - (r.initial + r.recurring + r.opportunity - r.net_proceeds)) <= 1
        end

        @testset "buying" begin
            b = cost(p; option="buy")
            @test b.initial      == 184_000  # 20% down + 3% closing
            @test b.recurring    == 246_052
            @test b.opportunity  == 81_606
            @test b.net_proceeds == 332_778  # home-sale proceeds
            @test b.total        == 178_881
            # Accounting identity (rounding can cause ±1)
            @test abs(b.total - (b.initial + b.recurring + b.opportunity - b.net_proceeds)) <= 1
        end

        @testset "buying is cheaper over 5 years" begin
            r = cost(p; option="rent")
            b = cost(p; option="buy")
            @test b.total < r.total
        end
    end

    @testset "cost — longer stay favours buying more" begin
        p_short = Param(stay=2.0)
        p_long  = Param(stay=15.0)
        r_short = cost(p_short; option="rent")
        b_short = cost(p_short; option="buy")
        r_long  = cost(p_long;  option="rent")
        b_long  = cost(p_long;  option="buy")
        # Advantage of buying should grow with longer stay
        savings_short = r_short.total - b_short.total
        savings_long  = r_long.total  - b_long.total
        @test savings_long > savings_short
    end

    @testset "cost — invalid option" begin
        @test_throws ErrorException cost(Param(); option="lease")
    end

end