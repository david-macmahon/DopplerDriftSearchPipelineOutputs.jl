using DelimitedFiles, DataFrames

function loaddat(fname)
    df = try
        dat = readdlm(fname, Any; comments=true)

        colnames = [
            "Top_Hit_Number", "Drift_Rate", "SNR", "Uncorrected_Frequency",
            "Corrected_Frequency", "Index", "freq_start", "freq_end", "SEFD",
            "SEFD_freq", "Coarse_Channel_Number", "Full_number_of_hits"
        ]

        DataFrame(dat, colnames)
    catch
        DataFrame()
    end

    metadata!(df, "datfile", basename(fname))

    df
end