module Registration

using CairoMakie
using FileIO
using GLMakie
using LinearAlgebra
using LsqFit
using Measurements
using MolecularGraph
using NMRTools
using Peaks
using Statistics
using TOML

using ..NMRScreen
using ..Types

export registration

include("types.jl")
include("nestedobservable.jl")
include("rpm.jl")
include("peaks.jl")
include("cocktails.jl")
include("state.jl")
include("gui.jl")
include("screeningpeaks.jl")
include("peaklist.jl")


"""
    registration(config, library, cocktails; peaklist=nothing)

Start the registration analysis interface, starting from the registration saved in
`peaklist` (a `peaklist.csv`, or a folder holding one) where given. On leaving, the
registration is saved as `peaklist.csv` in the output folder.

# Returns
- `cocktails`: Updated cocktails data structure
- `state`: Updated state data structure (for returning to the GUI)
"""
function registration(config, library, cocktails; peaklist=nothing)
    # 1. prepare registration cocktails, and restore any saved registration
    regcocktails = prepcocktails(cocktails)
    if !isnothing(peaklist)
        n = readpeaklist!(regcocktails, peaklist)
        @info "Restored $n peak(s) from $(peaklistfile(peaklist))"
    end

    # 2. initialise state for GUI
    state = initialisestate(config, library, regcocktails)

    # 3. show GUI
    registration(state)
end

# start registration from state - for returning to the GUI
function registration(state)
    gui!(state)
    writepeaklist(joinpath(state["config"].output_directory, "peaklist.csv"),
                  state["cocktails"])

    # 4. generate updated cocktails from state
    cocktails = recreatecocktails(state)

    return cocktails, state
end

end