using NMRScreen
using NMRScreen.Registration: RegistrationCocktail, writepeaklist, readpeaklist!, peaklistfile
using NMRScreen.Registration: Observable
using Test

@testset "NMRScreen.jl" begin
    @testset "Saving and restoring a registration" begin
        cocktail() = RegistrationCocktail("C1", "Cocktail 1", ["F1", "F1"], ["C", "C"],
                                          nothing, nothing, ["F1-a", "F1-b"], [-63.2, -60.0],
                                          Observable([-63.0, -59.9]),
                                          Observable([-63.1, -60.1]),
                                          Observable([true, false]), 0.1, -0.2)
        dir = mktempdir()
        path = writepeaklist(joinpath(dir, "out", "peaklist.csv"), [cocktail()])
        @test isfile(path)
        @test peaklistfile(joinpath(dir, "out")) == path
        # positions are saved on each spectrum's own scale, offsets added back
        lines = filter(l -> !startswith(l, "#"), readlines(path))
        @test lines[1] ==
              "label,fragment,cocktail,library (ppm),reference (ppm),bound (ppm),included"
        @test split(lines[2], ',')[[1, 3, 7]] == ["F1-a", "C1", "true"]
        @test parse(Float64, split(lines[2], ',')[5]) ≈ -62.9
        @test parse(Float64, split(lines[2], ',')[6]) ≈ -63.3

        # restored into a fresh registration, in its own aligned frame
        fresh = cocktail()
        fresh.ref_shifts[] .= 0.0
        fresh.bound_shifts[] .= 0.0
        fresh.good[] .= [false, true]
        @test readpeaklist!([fresh], joinpath(dir, "out")) == 2
        @test fresh.ref_shifts[] ≈ [-63.0, -59.9]
        @test fresh.bound_shifts[] ≈ [-63.1, -60.1]
        @test fresh.good[] == [true, false]

        @test_throws ArgumentError readpeaklist!([fresh], joinpath(dir, "nope.csv"))
    end
    @testset "An example screen writes its output elsewhere" begin
        toml = """
               [setup]
               name = "Test"
               date = "2024-11-11"
               operator = "A. Tester"
               spectrometer = "X"
               temperature = 298.0
               [files]
               fragment_library = "library.toml"
               experiment_directory = "data"
               output_directory = "out"
               [protein]
               name = "P"
               concentration = 1.0
               concentration_unit = "uM"
               buffer = "B"
               [[cocktails]]
               id = "C1"
               reference = "1"
               experiment = "101"
               """
        # a screen of one's own writes beside its experiment.toml
        dir = mktempdir()
        write(joinpath(dir, "experiment.toml"), toml)
        @test NMRScreen.parseconfig(joinpath(dir, "experiment.toml")).output_directory ==
              joinpath(dir, "out")
        # an example, inside a downloaded artifact, writes to the working directory
        depot = mktempdir()
        example = mkpath(joinpath(depot, "artifacts", "0a1b"))
        write(joinpath(example, "experiment.toml"), toml)
        pushfirst!(DEPOT_PATH, depot)
        try
            work = mktempdir()
            config = cd(() -> NMRScreen.parseconfig(joinpath(example, "experiment.toml")), work)
            @test config.output_directory == joinpath(realpath(work), "out")
            @test config.library_filename == joinpath(example, "library.toml")
        finally
            popfirst!(DEPOT_PATH)
        end
    end
end
