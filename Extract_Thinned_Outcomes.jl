
using JLD2
using DataFrames

# ---------------------------------------------------------------------------- #
#                     Compute Outcome Measures of Interest                     #
# ---------------------------------------------------------------------------- #

# ------------------- Prepare list of files for reading-in ------------------- #
file_list = readdir("Data/Objects/Thinned")
file_addresses = "Data/Objects/Thinned/" .* file_list




# ---------------------------------------------------------------------------- #
#                              Total Outbreak Size                             #
# ---------------------------------------------------------------------------- #

include("Helper_Functions.jl");
parameter_names = [:infect_prop_A, :infect_prop_I1, :infect_param_I2, :advance_prob_E,
                    :advance_prob_A, :advance_prob_I1, :advance_prob_I2, :E_to_A_prob, :threshold];


function build_size_data(file_addresses, j)
    ### Read dataset and extract contents
    output = load(file_addresses[j])

    pars_raw = output["parameters"]
    info = output["output"]


    ### Extract some useful values
    M = length(info)    # Number of replicates
    p = length(pars_raw)    # Number of parameters
    num_students = sum(info[1][1,:])

    ### Convert threshold parameter to an appropriate string
    T_num = pars_raw[end]
    T_str = string(T_num)
    
    ### Create new parameter vector
    pars = Vector{Any}(undef, p)
    for i in 1:(p-1)
        pars[i] = pars_raw[i]
    end
    pars[end] = T_str


### Get total size of each outbreak
    all_sizes = num_students .- iteration_compartment_summary(info, "S", minimum)


### Construct array of parameters
    array_pars = Array{Any}(undef, M, p)
    for i in 1:M
        array_pars[i,:] .= pars
    end


### Convert parameter array to a data frame
    size_data = DataFrame(array_pars, parameter_names)

### Add outbreak sizes
    size_data[:,"size"] = all_sizes

    size_data
end



all_size_data_pieces = @showprogress [build_size_data(file_addresses, i) for i in eachindex(file_addresses) ]

size_data = all_size_data_pieces[1]
for i in 2:length(all_size_data_pieces)
    append!(size_data, all_size_data_pieces[i])
end

CSV.write("Data/Output/Thinned/All_Outbreak_Sizes.csv", size_data)






# ---------------------------------------------------------------------------- #
#                              Peak Outbreak Size                              #
# ---------------------------------------------------------------------------- #

"""
Returns the peak number of total individuals in the provided components.

By default, returns the peak number of contagious individuals.
"""
function get_peak_size(traj, comps=[:A, :I1, :I2])
    M = nrow(traj)

    counts = zeros(M)
    for i in eachindex(counts)
        snapshot = traj[i,:]
        this_count = sum(snapshot[comps])
        counts[i] = this_count
    end
    
    return(maximum(counts))
end

function build_peak_data(file_addresses, j)
    ### Read dataset and extract contents
    output = load(file_addresses[j])

    pars_raw = output["parameters"]
    info = output["output"]


    ### Extract some useful values
    M = length(info)    # Number of replicates
    p = length(pars_raw)    # Number of parameters
    num_students = sum(info[1][1,:])

    ### Convert threshold parameter to an appropriate string
    T_num = pars_raw[end]
    T_str = string(T_num)
    
    ### Create new parameter vector
    pars = Vector{Any}(undef, p)
    for i in 1:(p - 1)
        pars[i] = pars_raw[i]
    end
    pars[end] = T_str


### Get peak size of each outbreak
    all_peaks = get_peak_size.(info)


### Construct array of parameters
    array_pars = Array{Any}(undef, M, p)
    for i in 1:M
        array_pars[i,:] .= pars
    end


### Convert parameter array to a data frame
    peak_data = DataFrame(array_pars, parameter_names)

### Add outbreak sizes
    peak_data[:,"peak"] = all_peaks

    peak_data
end



all_peak_data_pieces = @showprogress [build_peak_data(file_addresses, i) for i in eachindex(file_addresses) ]

peak_data = all_peak_data_pieces[1]
for i in 2:length(all_peak_data_pieces)
    append!(peak_data, all_peak_data_pieces[i])
end

CSV.write("Data/Output/Thinned/All_Outbreak_Peaks.csv", peak_data)



