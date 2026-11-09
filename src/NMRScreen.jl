module NMRScreen

using CairoMakie
using Distances
using FileIO
using GLMakie
using LinearAlgebra
using LsqFit
using Measurements
using MolecularGraph
using NMRTools
using Peaks
using RDKitMinimalLib
using Statistics
using TOML
using UMAP

export screen
export smilestoimage
# example data, from NMRExampleData through NMRTools
export example, examples, exampleinfo

# Include other source files
include("types.jl")
using .Types

include("config.jl")
include("library.jl")
include("cocktails.jl")
include("smiles.jl")
include("registration/Registration.jl")
include("relaxation/Relaxation.jl")

using .Registration
using .Relaxation


"""
    screen()

Entry point for the NMR fragment screening analysis application.

# Arguments
- `experiment_toml`: Path to the experiment configuration TOML file
- `peaklist`: a registration saved earlier, to carry on from: the `peaklist.csv` written to
  the output folder on leaving registration, or the folder holding it

# Example
```julia
screen("experiment.toml")
screen("experiment.toml"; peaklist="out")   # carry on from the registration saved in out
```
"""
function screen(experiment_toml::String; peaklist=nothing)
    GLMakie.activate!(;float=true, focus_on_show=true, title="NMRScreen.jl")
    config = parseconfig(experiment_toml)           # Load configuration
    library = parselibrary(config)                  # Load library definitions (fragments + cocktails)
    cocktails = loadcocktails(config, library)      # Load cocktail experimental data

    cocktails, regstate = registration(config, library, cocktails; peaklist)    # Start the registration analysis GUI

    while true
        finished = relaxation(config, library, cocktails)       # Start the relaxation analysis GUI

        finished && break
        cocktails, regstate = registration(regstate)            # Return to registration analysis
    end
end


"Entry point for command line usage."
function (@main)(args)
    try
        # Check for command line arguments
        if length(args) != 1
            println("Usage: nmrscreen <experiment_toml>")
            return 1
        end
        
        # Run main function with provided configuration
        screen(args[1])
        
        return 0
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
end

end # module

