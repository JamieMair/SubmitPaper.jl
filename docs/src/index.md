```@meta
CurrentModule = SubmitPaper
```

# SubmitPaper

Documentation for [SubmitPaper](https://github.com/JamieMair/SubmitPaper.jl). Written and maintained by [Jamie Mair](https://github.com/JamieMair).

`SubmitPaper.jl` is very simple package to automate submitting a paper to arXiv or journal which requires a flat directory structure with a single `.tex` file, while being able to keep your code clean and well-structured. The aim is to eliminate any manual copying and pasting to produce output that can be used by the journals' compilers.

The main command will analyse a supplied directory for a $\LaTeX$ project and create a new submission folder with the modified files. The package **does not** modify any existing files in the directory. `SubmitPaper.jl` assumes a $\LaTeX$ project directory structure with a `main.tex` file (`main` could be something else) which contains a `\documentclass` line as well as a `\begin{document}` line. The package will search for these `root` files within a specified directory. It will then look for any `\input` or `\include` commands in the `.tex` file and replace them with the actual contents of the corresponding file. Additionally, any figures referenced by the `\includegraphics` command will have the path modified to point at the file name of the figure and copy the original figure into the submission directory.

## Requirements

- A $\LaTeX$ distribution must be installed on the system.
- `latexmk` (an automatic $\LaTeX$ compiler) is essential as it is used for compilation. Currently, the tool does not support compilation via other means or customisable options.

## Basic Usage

First, make sure you have Julia installed on your system. We recommend using `juliaup`(https://github.com/JuliaLang/juliaup) if you have not installed Julia already. Then, run the following command to install the `SubmitPaper.jl` package:
```bash
julia -e 'using Pkg; Pkg.add("https://github.com/JamieMair/SubmitPaper.jl");'
```
This will install to your global directory, allowing use of the package from anywhere.

Next, find the absolute path to the directory containing your $\LaTeX$ project (e.g. `"path/to/project"`) and run the following from the command line to create the submission folder:
```bash
julia -e 'using SubmitPaper; package("path/to/project")'
```
This should create your submission at `"path/to/project/submission"` by default. 


For more help, check the documentation for the `package` function by opening a Julia REPL (type `julia` into the command line) and use the `?` character to open the help menu:
```
julia> using SubmitPaper
help?> package
```


# API
```@autodocs
Modules = [SubmitPaper]
```
