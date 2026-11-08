struct RegistrationCocktail
    id
    name
    fragment_ids
    smiles
    refspec
    boundspec
    peak_ids
    library_shifts
    ref_shifts
    bound_shifts
    good::Observable{Vector{Bool}}
    refoffset::Float64      # alignment offsets applied to the reference and bound spectra
    boundoffset::Float64
end
