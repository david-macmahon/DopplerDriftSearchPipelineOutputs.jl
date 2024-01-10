using Arrow
using DataFrames

"""
    loadhits(arrowname) -> DataFrame

Load DataFrame `df` of hots from Arrow file `arrowname`.  Metadata from
`arrowname` will be copied to metadata in the returned DataFrame, with
recognized numeric fields converted to numeric values.
"""
function loadhits(arrowname::AbstractString)::DataFrame
    tbl = Arrow.Table(arrowname)
    df = DataFrame(tbl; copycols=true)
    for (k,v) in Arrow.getmetadata(tbl)
        if k in ("datafile", "source_name")
            vany = v
        elseif k in ("nfpc", "nchans", "nsamps", "nrates")
            vany = something(tryparse(Int, v), v)
        elseif k in ("startrate", "deltarate", "snr", "radius",
                     "fch1", "foff", "tstart", "tsamp", "ra", "dec", "dfdt")
            vany = something(tryparse(Float64, v), v)
        # `numrates` was original name of `nrates`
        elseif k == "numrates"
            k = "nrates" # Silently translate to new name
            vany = something(tryparse(Int, v), v)
        else
            @warn "unknown metadata field $k"
            vany = v
        end
        metadata!(df, k, vany; style=:note)
    end

    df
end
