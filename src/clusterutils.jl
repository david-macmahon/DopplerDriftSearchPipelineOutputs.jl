"""
    clusterizeprotohits(hijs, radius=20; kwargs...) -> [cijs1, cijs2, ...]

Group the *proto-hits* in `hijs` into clusters.  All members of a cluster will
be within a distance of `radius` from at least one other cluster member.  This
uses the `dbscan` function from Clustering.jl.  The resulting clusters are
returned as a `Vector{Vector{CartesianIndex}}` where each
`Vector{CartesianIndex}` contains `CartesianIndex` values that belong to the
same cluster.  Any given `kwargs` are passed through to `dbscan`.
"""
function clusterizeprotohits(hijs, radius=20; kwargs...)
    if length(hijs) > 2 # 3 or more proto-hits
        hitm = similar(hijs, Float32, 2, length(hijs))
        hitm[1,:] .= first.(Tuple.(hijs))
        hitm[2,:] .= last.(Tuple.(hijs))
        cresults = dbscan(hitm, radius; kwargs...)
        return [vcat(hijs[c.core_indices],
                     hijs[c.boundary_indices]) for c in cresults.clusters]
    elseif length(hijs) == 2
        a, b = hijs
        if hypot(Tuple(a-b)...) > radius
            # Two "clusters" of one proto-hit each
            return [[a], [b]]
        else
            # One "cluster" of two proto-hits
            return [hijs]
        end
    elseif length(hijs) == 1
        # One "cluster" of one proto-hit
        return [hijs]
    else
        # Zero clusters
        return typeof(hijs)[]
    end
end

"""
    clusterpeak([f,] cijs, fdr) -> (; pkval, pkchan, pkrateidx)

Finds the max value of `fdr[cijs]` and the CartesianIndex of the peak in `fdr`.
The `cijs` are all the CartesianIndex values that correspond to the same
cluster.  If function `f` is given, it will be passed the cluster's max value
and its return value will be returned as the peak value.  This allows a user
supplied function to normalize (or otherwise modify) the peak value.
"""
function clusterpeak(f::Function, cijs, fdr)
    isempty(cijs) && error("no points in cluster")
    pkval, pkidx = findmax(@view fdr[cijs])
    pkval = f(pkval)
    pkchan, pkrateidx = Tuple(cijs[pkidx])
    (; pkval, pkchan, pkrateidx)
end

function clusterpeak(cijs, fdr)
    clusterpeak(identity, cijs, fdr)
end

"""
    clusterinfo([f,] cijs, fdr; chans, freqs, rates) -> NamedTuple
    clusterinfo([f,] id, cijs, fdrs; chans, freqs, rates) -> NamedTuple
    clusterinfo.([f,] ids, cijss, Ref(fdr); chans, freqs, rates) -> Vector{NamedTuple}
    clusterinfo([f,] ids, cijss, fdrs; chans, freqs, rates) -> Vector{NamedTuple}

Returns a NamedTuple of metadata about the proto-hit cluster comprised of points
`cijs` (typically a `Vector{CartesionIndex}`) in FDR matrix `fdr` or `fdrs`, a
Vector of *batched* FDR matrices they are treated as drift rate adjacent
portions of a larger FDR matrix).  To get cluster info for multiple clusters
from a single (unbatched) FDR, broadcast over `ids` and `cijss`, but wrap `fdr`
in a `Ref`, as shown in the third form.  To get cluster info for multiple
clusters from multiple (batched) FDRs matrices, use the fourth form rather than
broadcasting.

Each returned `NamedTuple` will have the following fields:

- `id` - The `id` assigned to the cluster by the caller
- `pkval` - The value of the cluster's peak proto-hit
- `pkchan` - The (starting) channel of the cluster's peak proto-hit
- `pkfreq` - The (starting) frequency of the cluster's peak proto-hit
- `pkrate` - The drift rate of the cluster's peak proto-hit
- `nhits` - The number of proto-hits in the cluster
- `lochan` - The lowest (starting) channel of the cluster's proto-hits
- `hichan` - The highest (starting) channel of the cluster's proto-hits
- `lorateidx` - The lowest drift rate index of the cluster's proto-hits
- `pkrateidx` - The index of the drift rate of the cluster's peak proto-hit
- `hirateidx` - The highest drift rate index of the cluster's proto-hits
- `lofreq` - The lowest (starting) frequency of the cluster's proto-hits
- `hifreq` - The highest (starting) frequency of the cluster's proto-hits
- `lorate` - The lowest drift rate of the cluster's proto-hits
- `hirate` - The highest drift rate of the cluster's proto-hits

If function `f` is given, it will be passed the cluster's peak value and its
return value will be used as the `pkval` value.  This allows a user supplied
function to normalize (or otherwise modify) the reported `pkval` values.

`freqs` and `rates` may be passed as Ranges (or Vectors) of frequencies and
drift rates.  The returned `??freq` and `??rate` fields will be looked up from
`freqs` and `rates`.  If `freqs` and/or `rates` are not passed, they default to
the range of the relevant axes in `fdr`.  These defaults values will lead to
`??freq` being the same as `??chan` and `??rate` being the same as `??rateidx`,
which is generally not very useful but may be convenient during development.
"""
function clusterinfo(f::Function, id, cijs::Vector{CartesianIndex{2}},
                     fdr::AbstractMatrix;
                     chans=axes(fdr, 1), freqs=axes(fdr,1), rates=axes(fdr,2))
    isempty(cijs) && error("no points in cluster")
    pkval, pkchan, pkrateidx = clusterpeak(f, cijs, fdr)
    nhits = length(cijs)
    (lochan, lorateidx), (hichan, hirateidx) = Tuple.(extrema(cijs))
    lofreq = freqs[lochan]
    pkfreq = freqs[pkchan]
    hifreq = freqs[hichan]
    lorate = rates[lorateidx]
    pkrate = rates[pkrateidx]
    hirate = rates[hirateidx]

    # Convert FDR channel indices to user channels
    lochan = chans[lochan]
    pkchan = chans[pkchan]
    hichan = chans[hichan]

    (; id, pkval,
       pkchan, pkfreq, pkrate, nhits,
       lochan, hichan,
       lorateidx, pkrateidx, hirateidx,
       lofreq, hifreq,
       lorate, hirate)
end

# Single cluster, single FDR (`f` defaults to `identity`)
function clusterinfo(id, cijs::Vector{CartesianIndex{2}},
                     fdr::AbstractMatrix;
                     chans=axes(fdr, 1), freqs=axes(fdr,1), rates=axes(fdr,2))
    clusterinfo(identity, id, cijs, fdr; chans, freqs, rates)
end

# Single cluster, batched FDRs
function clusterinfo(f::Function, id, cijs::Vector{CartesianIndex{2}},
                     fdrs::AbstractVector{<:AbstractMatrix};
                     chans=1:size(fdrs[1], 1), freqs=1:size(fdrs[1], 1),
                     rates=1:sum(size.(fdrs,2)))
    if length(fdrs) == 1
        fdr = first(fdrs)
    else
        # Use `mortar` from BlockArrays to make "super-array"
        fdr = mortar(reshape(fdrs, 1, :))
    end
    clusterinfo(f, id, cijs, fdr; chans, freqs, rates)
end

# Single cluster, batched FDR (`f` defaults to `identity`)
function clusterinfo(id, cijs::Vector{CartesianIndex{2}},
                     fdrs::AbstractVector{<:AbstractMatrix};
                     chans=1:size(fdrs[1], 1), freqs=1:size(fdrs[1], 1),
                     rates=1:sum(size.(fdrs,2)))
    clusterinfo(identity, id, cijs, fdrs; chans, freqs, rates)
end

# Multiple clusters, batched FDR
function clusterinfo(f::Function, ids, cijss::Vector{Vector{CartesianIndex{2}}},
                      fdrs::AbstractVector{<:AbstractMatrix};
                      chans=1:size(fdrs[1], 1), freqs=1:size(fdrs[1], 1),
                      rates=1:sum(size.(fdrs,2)))
    if length(fdrs) == 1
        fdr = first(fdrs)
    else
        # Use `mortar` from BlockArrays to make "super-array"
        fdr = mortar(reshape(fdrs, 1, :))
    end
    clusterinfo.(f, ids, cijss, Ref(fdr); chans, freqs, rates)
end

# Multiple clusters, batched FDR (`f` defaults to `identity`)
function clusterinfo(ids, cijss::Vector{Vector{CartesianIndex{2}}},
                      fdrs::AbstractVector{<:AbstractMatrix};
                      chans=1:size(fdrs[1], 1), freqs=1:size(fdrs[1], 1),
                      rates=1:sum(size.(fdrs,2)))
    clusterinfo(identity, ids, cijss, fdrs; chans, freqs, rates)
end
