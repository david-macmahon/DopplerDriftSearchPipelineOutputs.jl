using DataFrames
using SortMerge

function fuzzysd(v1, v2, i1, i2, c1, c2, fuzz1, fuzz2, dt=0)
    # vals1 and vals2 are (freq_mhz, rate)
    vals1 = values(v1[i1, c1])
    vals2 = values(v2[i2, c2])
    # extrapolate vals1 freq
    vals1 = (vals1[1] + dt * vals1[2] / 1e6, vals1[2])
    diffs = vals1 .- vals2
    for (i,(d,f)) in enumerate(zip(diffs, (fuzz1, fuzz2)))
        (abs(d) > abs(f))  &&  (return i*sign(d))
    end
    return 0
end

"""
    fuzzymatch(df1, df2, frfuzz, drfuzz, dt=0;
               cols1=[:pkfreq, :pkrate], cols2=cols1)

Performs a fuzzy match between hits in `df1` and hits in `df2` using a time,
frequency, and drift rate aware matching algorithm.  The `df1` and `df2` inputs
must be DataFrame objects. The default columms used by `fuzzymatch` are
`[:pkfreq, :pkrate]`, but this can be overridden for each input dataframe via
the `cols1` and `cols2` keyword arguments.  Returns a `SortMerge.Matched`
object.
"""
function fuzzymatch(df1::DataFrame, df2::DataFrame, frfuzz, drfuzz, dt=0;
                    cols1=[:pkfreq, :pkrate], cols2=[:pkfreq, :pkrate],
                    sorted=false)
    sortmerge(df1, df2, cols1, cols2, frfuzz, drfuzz, dt; sorted,
        lt1=(v,i,j)->v[i, cols1] < v[j, cols1],
        lt2=(v,i,j)->v[i, cols2] < v[j, cols2],
        sd=fuzzysd
    )
end
