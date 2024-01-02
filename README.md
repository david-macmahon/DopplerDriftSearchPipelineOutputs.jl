# DopplerDriftSearchPipelineOutputs

This package provides functionality for working with data in the output files
created by the `DopplerDriftSearchPipeline` package.  The output files contain
records of *hits* that were detected by the search pipeline.  A *hit* is a
detection of a signal that drifts in frequency over time with integrated power
greater than or equal to a given threshold.  Often there will be multiple
*ptoto-hits* clustered near each other in the *frequency vs drift rate*
detection plane.  Each cluster of proto-hits is recorded as a single hit with
starting frequency and drift rate of the proto-hit with the highest value
among all proto-hits of the cluster.

# DopplerDriftSearchPipeline output files

The output files from `DopplerDriftSearchPipeline` are stored in the Apache
Arrow format.  Each file includes some general metadata that apply to all the
hits in the file:

- `datafile`: The name of the input file (basename, no directory info).
- `fch1`: The frequency of the first channel of the input file (in MHz).
- `foff`: The width of each channel in the input file (in MHz).
- `tstart`: The start time of the data in the input file (in MJD).
- `tsamp`: The time step between time samples, i.e. spectra (in seconds).
- `source_name`: The source name as given in the input file's header.
- `ra`: The right ascension of the source (in hours)
- `dec`: The declination of the source
- `dfdt`: The ratio of `1e6*foff/tsamp`, which is `Hz/s` drift rate
  corresponding to one channel step per time step.
- `nfpc`: The number of fine channels per chunk processed.  This is almost
  always the same as the number of file channels per coarse channel.
- `startrate`: The first drift rate in the range of searched drift rates (in
  Hz/s).
- `deltarate`: The step size of the range of drift rates searched (in Hz/s).
- `numrates`: The number of drift rates that were searched.
- `snr`: The SNR threshold that was used to detect proto-hits.
- `radius`: The distance threshold used when clustering proto-hits (pixels).

Each hit contains the following fields:

- `id`: Non-unique ID (not very useful in post processing)
- `pkval`: The value of the hit (i.e. the peak proto-hit) in the cluster.  If
  the detection plane values have had its mean subtracted and the standard
	deviation divided out, as DopplerDriftSearchPipeline does, then this is also
  referred to as the hit's *signal-to-noise ratio* (SNR).
- `pkchan`: The channel of the hit in the first time sample (i.e. spectrum) of
  the input file.  This value is relative to the input file.
- `pkfreq`: The topocentric frequency of the hit in the first time sample.
- `pkrate`: The drift-rate of the hit in `Hz/s`.
- `nhits`: The number of proto-hits in this hit's cluster.
- `lochan`: The lowest channel of all proto-hits in this hit's cluster.
- `hichan`: The highest channel of all proto-hits in this hit's cluster.
- `lorateidx`: The index of the lowest drift rate of all proto-hits in this
  hit's cluster.
- `pkrateidx`: The index of the drift rate of the peak proto-hit of this
  hit's cluster (i.e. of this hit).
- `hirateidx`: The index of the highest drift rate of all proto-hots in this
  hit's cluster. 
- `lofreq`: The lowest frequency of all proto-hits in this hit's cluster.
- `hifreq`: The highest frequency of all proto-hits in this hit's cluster.
- `lorate`: The lowest drift rate of all proto-hits in this hit's cluster.
- `hirate`: The highest drift rate of all proto-hits in this hit's cluster.

The fields whose names start with `pk` describe the hit (i.e. the peak
proto-hit of the cluster).  `nhits` and the various `lo`/`hi` fields are
intended to give some general indication of the morphology of the proto-hit
cluster.

# Loading hits

To load a hits file use the `loadhits` function, which reads in the specified
Arrow file and converts it into a `DataFrame` for easy manipulation.  The
returned DataFrame has one row per hit as well as the file level metadata
described above.

```julia
julia> using DopplerDriftSearchPipelineOutputs

julia> df=loadhits("guppi_59103_05106_TIC424865156_0020.rawspec.0000.arrow")
58410×15 DataFrame
   Row │ id     pkval       pkchan     pkfreq    pkrate       nhits   lochan   ⋯
       │ Int64  Float32     Int64      Float64   Float64      Int64   Int64    ⋯
───────┼────────────────────────────────────────────────────────────────────────
     1 │     1  1075.65       1843519  2246.31    2.28083e-7   29803    184312 ⋯
     2 │     1  1451.67        416959  2250.3    -0.0306125    71318     41656
     3 │     2   146.379       417682  2250.3     0.193881    118964     41726
     4 │     3   218.519       524289  2250.0    -0.010204     57288     52389
     5 │     4   146.379       630896  2249.7    -0.193881    118965     63052 ⋯
     6 │     5  1451.67        631619  2249.7     0.030613     71318     63122
     7 │     6    22.0942      309630  2250.6    -0.0408168      530     30961
   ⋮   │   ⋮        ⋮           ⋮         ⋮           ⋮         ⋮         ⋮    ⋱
 58405 │     5     8.68968  527627956   777.289   2.28083e-7       1  52762795
 58406 │     6     9.49958  527629571   777.285   2.28083e-7       1  52762957 ⋯
 58407 │     7     8.08033  527646953   777.236   0.0102045        2  52764695
 58408 │     1    20.6251   533115565   761.957   2.28083e-7    1600  53311551
 58409 │     2    21.3459   533117436   761.952  -0.010204       467  53311741
 58410 │     3    11.7194   533095332   762.014  -0.010204        51  53309532 ⋯
                                                9 columns and 58397 rows omitted
```

The metadata of the DataFrame can be obtained with the `metadata` function:

```julia
ulia> metadata(df)
Dict{String, Any} with 15 entries:
  "numrates"    => 785
  "fch1"        => 2251.46
  "nfpc"        => 1048576
  "foff"        => -2.79397e-6
  "startrate"   => -4.00007
  "deltarate"   => 0.0102043
  "tstart"      => 59103.1
  "dec"         => 47.9695
  "radius"      => 20.0
  "ra"          => 19.4831
  "source_name" => "TIC424865156"
  "dfdt"        => -0.153064
  "tsamp"       => 18.2536
  "snr"         => 8.0
  "datafile"    => "guppi_59103_05106_TIC424865156_0020.rawspec.0000.h5"
```

# Matching hits

Matching hits across different files created from the same input file can be
useful for testing/verification.  Matching hits across hits files from
neighboring scans is one way to find/filter *events*, which can be used to
determine whether the hits have a terrestrial or extraterrestrial origin.

The short term Doppler drift is modeled as a straight line, but over longer
periods Doppler drifting signals exhibit non-linear drifts in frequency.
Modeling these higher order frequency drift effects can be tricky.  A less
analytical approach is to allow for some error in the matching process.

The `fuzzymatch` function will match hits from two `DataFrames` based on their
`pkfreq` and `pkrate` columns using caller supplied tolerances (aka *fuzz*) for
frequency and drift rate.  Additionally, `fuzzymatch` accepts a parameter that
specifies the difference between start times of the data files.  This value,
referred to as `dt`, is used to extrapolate the starting frequency of a hit in
the first `DataFrame` to the starting time of the second `DataFrame` using the
hit's drift rate.  For this to work, `dt` must be given in seconds and the
`pkfreq` columns must be in `MHz`.  The default value for `dt` is 0 (i.e. no
extrapolation by default).

The implementation of `fuzzymatch` uses `SortMerge.jl`.  The object returned by
`sortmerge` is also returned from `fuzzysearch`.  See the documentation of
`SortMerge.jl` for more details on how to interpret/use the output.

Here is an example that shows 3645 hits from `df1` match with 3645 hits from
`df2` when allowing for tolerances of one frequency channel and one drift rate
step and accounting for the time difference `dt` between `df1` and `df2`:

```julia
julia> j=fuzzymatch(df1, df2, foff, deltarate, dt)
Input 1:         3645 /        58410  (  6.24%), min/max mult.:      1 :      1
Input 2:         3645 /        51946  (  7.02%), min/max mult.:      1 :      1
Output :         3645
```

# Other functionality

The `turboSETI` Python package, an early Doppler drift search pipeline, outputs
a `.dat` file containing all the hits it found.  The `.dat` files are text files
starts with comment lines followed by whitespace delimited tabular data with
predefined columns.  `DopplerDriftSearchPipelineOutputs` includes a `readdat()`
function to parses `turboSETI` `.dat` files using the `DelimitedFiles` package
and returns the tablular data as a `DataFrame`.  As of this writing, the columns
in a `.dat` file are named:

- `Top_Hit_Number`
- `Drift_Rate`
- `SNR`
- `Uncorrected_Frequency`
- `Corrected_Frequency`
- `Index`
- `freq_start`
- `freq_end`
- `SEFD`
- `SEFD_freq`
- `Coarse_Channel_Number`
- `Full_number_of_hits`

See the turboSETI docs (and/or source code) for the definitions/descriptions
of these fields.  Note that `readdat` does not parse the metadata in the
freeform comment lines that preceed the tablular data, but it does add one
metadata field, `datfil`, to the returned `DataFrame` to indicate the name of
the `.dat` file (excluding directories).

For comparision of `turboSETI` outputs with `DopplerDriftSearchPipeline``
outputs, one can pass a `DataFrame` returned by `loadhits` and another returned
by `loaddat` to `fuzzymatch` along with a `cols1` or `cols2` keyword argument
containing the relevant colume names to use for the `.dat` file's `DataFrame`,
namely `[:Uncorrected_Frequency, :Drift_Rate]`
