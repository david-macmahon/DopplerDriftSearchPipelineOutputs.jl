module DopplerDriftSearchTools

using Arrow
using BlockArrays: mortar
using Clustering: dbscan
using DataFrames
using DelimitedFiles
using SortMerge
using StatsBase

export clusterizeprotohits
export clusterinfo
export hitsearchmetadata
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

include("clusterutils.jl")
include("extstubs.jl")
include("hitsearchmetadata.jl")
include("loadhits.jl")
include("loaddat.jl")
include("fuzzymatch.jl")
include("rangeutils.jl")

end # module DopplerDriftSearchTools
