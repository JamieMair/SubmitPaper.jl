using SubmitPaper
using Documenter

DocMeta.setdocmeta!(SubmitPaper, :DocTestSetup, :(using SubmitPaper); recursive=true)

makedocs(;
    modules=[SubmitPaper],
    authors="Jamie Mair <JamieMair@users.noreply.github.com> and contributors",
    repo="https://github.com/JamieMair/SubmitPaper.jl/blob/{commit}{path}#{line}",
    sitename="SubmitPaper.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JamieMair.github.io/SubmitPaper.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JamieMair/SubmitPaper.jl",
    devbranch="master",
)
