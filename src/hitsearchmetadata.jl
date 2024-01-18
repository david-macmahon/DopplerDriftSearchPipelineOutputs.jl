"""
    hitsearchmetadata(;
        datafile, fch1, foff, nchans, tstart, tsamp, nsamps, source_name,
        ra, dec, chunkchans, startrate, deltarate, nrates, snr, radius)

Make a Vector{Pair{String,Any}} that reflects metadata from the input data file
and doppler drift search parameters.  Each keyword argument corresponds to a
metadata field of the same name.  The keyword arguments, which are all
mandatory, are described in the extended help (`??makemetadata` in the Julia
REPL).

# Extended help

An extra metadata field, `dfdt`, is derived from the `foff` and `tsamp` keyword
arguments.  The `dfdt` metadata field is included in the table below, but is
not a supported keyword argument.

| Name        | Description                                         |
|:------------|:----------------------------------------------------|
|`datafile`   | Filename of input data file (only basename stored)  |
|`fch1`       | Frequency of first channel in `datafile` (MHz)      |
|`foff`       | Channel width in `datafile` (MHz)                   |
|`nchans`     | Number of channels in `datafile`                    |
|`tstart`     | Start time of `datafile` (MJD)                      |
|`tsamp`      | Integration time of each sample in `datafile` (sec) |
|`nsamps`     | Number of samples in `datafile`                     |
|`source_name`| Source name from header of `datafile`               |
|`ra`         | Right ascension if source (hours)                   |
|`dec`        | Declination of source (degrees)                     |
|`dfdt`       | Channel width / tsamp (Hz/s)                        |
|`chunkchans` | Number of channels searched at one time             |
|`startrate`  | First drift rate of searched range (Hz/s)           |
|`deltarate`  | Step size of searched drift rate range (Hz/s)       |
|`nrates`     | Total number of drift rates searched                |
|`snr`        | SNR threshold used to find proto-hits               |
|`radius`     | Radius used when clustering proto-hits              |
"""
function hitsearchmetadata(;
    datafile, fch1, foff, nchans, tstart, tsamp, nsamps, source_name,
    ra, dec, chunkchans, startrate, deltarate, nrates, snr, radius
)
    [
        "datafile"    => basename(datafile),
        "fch1"        => convert(Float64, fch1),
        "foff"        => convert(Float64, foff),
        "nchans"      => convert(Int,     nchans),
        "tstart"      => convert(Float64, tstart),
        "tsamp"       => convert(Float64, tsamp),
        "nsamps"      => convert(Int,     nsamps),
        "source_name" => string(          source_name),
        "ra"          => convert(Float64, ra),
        "dec"         => convert(Float64, dec),
        "dfdt"        => convert(Float64, foff) * 1e6 / tsamp,
        "chunkchans"  => convert(Int,     chunkchans),
        "startrate"   => convert(Float64, startrate),
        "deltarate"   => convert(Float64, deltarate),
        "nrates"      => convert(Int,     nrates),
        "snr"         => convert(Float64, snr),
        "radius"      => convert(Float64, radius)
    ]
end
