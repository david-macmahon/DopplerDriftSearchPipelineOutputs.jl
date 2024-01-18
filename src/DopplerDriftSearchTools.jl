module DopplerDriftSearchTools

using Arrow
using DataFrames
using DelimitedFiles
using SortMerge

export loadhits
export loaddat
export fuzzymatch

# For Julia < 1.9.0
if !isdefined(Base, :get_extension)
    # Add DataFrame constructor for Vector{Filterbank.Header} if/when DataFrames
    # is imported.
    using Requires
end
@static if !isdefined(Base, :get_extension)
    function __init__()
        @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
            include("../ext/PlotsFrequencyDriftRateTransformsExt.jl")
        end
    end
end

include("extstubs.jl")
include("loadhits.jl")
include("loaddat.jl")
include("fuzzymatch.jl")

end # module DopplerDriftSearchTools
