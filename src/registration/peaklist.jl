# The registration saved as `peaklist.csv` in the output folder: where each fragment peak was
# placed in the reference and bound spectra, and whether it is included. Positions are on
# each spectrum's own ppm scale, before the alignment offsets that registration applies, so
# a saved list still fits if the alignment found differs.

const PEAKLIST_HEADER = ["label", "fragment", "cocktail", "library (ppm)", "reference (ppm)",
                         "bound (ppm)", "included"]

"""
    peaklistfile(path) -> String

The peak list a `peaklist` argument names: the file itself, or the `peaklist.csv` in a
folder, such as an output folder saved earlier.
"""
peaklistfile(path::AbstractString) = isdir(path) ? joinpath(path, "peaklist.csv") : path

csvcell(x) = replace(string(x), "," => "")

"""
    writepeaklist(path, cocktails)

Write the registration of `cocktails` as a peak list, one row per fragment peak.
"""
function writepeaklist(path::AbstractString, cocktails)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# NMRScreen.jl registration: positions in each spectrum's own ppm scale")
        println(io, join(PEAKLIST_HEADER, ","))
        for c in cocktails, i in eachindex(c.peak_ids)
            row = [csvcell(c.peak_ids[i]), csvcell(c.fragment_ids[i]), csvcell(c.id),
                   c.library_shifts[i], c.ref_shifts[][i] + c.refoffset,
                   c.bound_shifts[][i] + c.boundoffset, c.good[][i]]
            println(io, join(string.(row), ","))
        end
    end
    return path
end

"""
    readpeaklist!(cocktails, path) -> Int

Restore a saved registration into `cocktails`, before the window opens: each peak in the
list is placed where it was saved and included or not as it was. Peaks the list does not
mention keep the positions found automatically. Returns the number of peaks restored.
"""
function readpeaklist!(cocktails, path::AbstractString)
    file = peaklistfile(path)
    isfile(file) || throw(ArgumentError("no peak list at $file"))
    lines = filter(l -> !isempty(strip(l)) && !startswith(strip(l), "#"), readlines(file))
    isempty(lines) && throw(ArgumentError("$file holds no peaks"))
    # columns are found by name, with any parenthesised unit stripped
    names = [lowercase(strip(replace(h, r"\s*\(.*\)$" => ""))) for h in split(first(lines), ',')]
    col(name) = @something(findfirst(==(name), names),
                           throw(ArgumentError("$file has no $name column")))
    label, cocktail, ref, bound, included = col.(["label", "cocktail", "reference", "bound",
                                                   "included"])
    saved = Dict{Tuple{String,String},NTuple{3,Float64}}()
    for line in lines[2:end]
        f = strip.(split(line, ','))
        saved[(f[cocktail], f[label])] = (parse(Float64, f[ref]), parse(Float64, f[bound]),
                                         parse(Bool, f[included]))
    end
    n = 0
    for c in cocktails, i in eachindex(c.peak_ids)
        key = (string(c.id), string(c.peak_ids[i]))
        haskey(saved, key) || continue
        r, b, g = saved[key]
        c.ref_shifts[][i] = r - c.refoffset
        c.bound_shifts[][i] = b - c.boundoffset
        c.good[][i] = g
        n += 1
    end
    return n
end
