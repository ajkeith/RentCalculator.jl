using RentCalculator
using Documenter

makedocs(;
    modules=[RentCalculator],
    authors="Andrew Keith",
    repo="https://github.com/ajkeith/RentCalculator.jl/blob/{commit}{path}#L{line}",
    sitename="RentCalculator.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ajkeith.github.io/RentCalculator.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ajkeith/RentCalculator.jl",
)
