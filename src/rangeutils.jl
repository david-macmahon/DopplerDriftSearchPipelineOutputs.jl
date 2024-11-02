"""
    clampci(ci::CartesianIndex; [lolim], [hilim])

Clamp `ci` components to be no lower than `lolim` (defaults to
`CartesianIndex(1,...)`) and no higher than `hilim` (defaults to
`CartesianIndex(typemax(Int),...)`).
"""
function clampci(r::CartesianIndex{N};
                 lolim=CartesianIndex{N}(ntuple(i->1, N)),
                 hilim=CartesianIndex{N}(ntuple(i->typemax(Int), N))) where N
    clamp.(Tuple(r), Tuple(lolim), Tuple(hilim)) |> CartesianIndex
end

"""
    clamprange(r::CartesianIndices, array::AbstractArray)

Clamp the CartesianIndices range `r` to the dimensions of `a`.
"""
function clamprange(r::CartesianIndices, array::AbstractArray)
    lo = first(r)
    hi = last(r)
    lolim = first(CartesianIndices(array))
    hilim = last(CartesianIndices(array))
    clampci(lo; lolim):step(r):clampci(hi; hilim)
end

"""
    clusterrange(cijs, array, border=0) -> CartesianIndices

Compute the rectangular region of `array` that contains CartesianIndex values in
`cijs`.  The `border` argument may be used to add a border to the region.  When
given, `border` must be an `Int` (same border size in all directions) or a
`CartesianIndex` or `Tuple` of dimensionality/length of `ndims(array)` giving
the border size for both sides of each dimension.  The returned
`CartesianIndices` region will be clipped to the size of `array` if necessary.
"""
function clusterrange(
    cijs::AbstractVector{CartesianIndex{N}},
    array::AbstractArray{T,N},
    border::CartesianIndex{N}=CartesianIndex(ntuple(_->0, N))
) where {T,N}
    isempty(cijs) && error("no points in range")
    lo, hi = extrema(cijs)
    lo -= border
    hi += border
    lolim, hilim = extrema(CartesianIndices(array))
    clampci(lo; lolim):clampci(hi; hilim)
end

function clusterrange(cijs, array, border)
    clusterrange(cijs, array, CartesianIndex(border))
end

function clusterrange(cijs, array::AbstractArray{T,N}, border::Int) where {T,N}
    clusterrange(cijs, array, ntuple(_->border, N))
end
