
# ---------------------------------------------------------------------------- #
#                     Compute Outcome Measures of Interest                     #
# ---------------------------------------------------------------------------- #

# ------------------- Prepare list of files for reading-in ------------------- #
file_list = readdir("Data/Objects/M=10")
file_addresses = "Data/Objects/M=10/" .* file_list




# ---------------------------------------------------------------------------- #
#                              Total Outbreak Size                             #
# ---------------------------------------------------------------------------- #


# function build_size_data(file_addresses, j)
#     ### Read dataset and extract contents
#     output = load(file_addresses[j])

#     pars_raw = output["parameters"]
#     info = output["output"]


#     ### Extract some useful values
#     M = length(info)    # Number of replicates
#     p = length(pars_raw)    # Number of parameters
#     num_students = sum(info[1][1,:])

#     ### Convert threshold parameter to an appropriate string
#     T_num = pars_raw[end]
#     T_str_raw = string(T_num)
#     T_str_end = match(r"\(.+$", T_str_raw).match
#     T_str = match(r"[^\(\)]+", T_str_end).match
    
#     ### Create new parameter vector
#     pars = Vector{Any}(undef, p)
#     for i in 1:(p-1)
#         pars[i] = pars_raw[i]
#     end
#     pars[end] = T_str


# ### Get total size of each outbreak
#     all_sizes = num_students .- iteration_compartment_summary(info, "S", minimum)


# ### Construct array of parameters
#     array_pars = Array{Any}(undef, M, p)
#     for i in 1:M
#         array_pars[i,:] .= pars
#     end


# ### Convert parameter array to a data frame
#     size_data = DataFrame(array_pars, parameter_names)

# ### Add outbreak sizes
#     size_data[:,"size"] = all_sizes

#     size_data
# end



# all_size_data_pieces = @showprogress [build_size_data(file_addresses, i) for i in eachindex(file_addresses) ]

# size_data = all_size_data_pieces[1]
# for i in 2:length(all_size_data_pieces)
#     append!(size_data, all_size_data_pieces[i])
# end

# CSV.write("Data/Output/All_Outbreak_Sizes.csv", size_data)






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
    T_str_raw = string(T_num)
    T_str_end = match(r"\(.+$", T_str_raw).match
    T_str = match(r"[^\(\)]+", T_str_end).match
    
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

CSV.write("Data/Output/All_Outbreak_Peaks.csv", peak_data)





# ---------------------------------------------------------------------------- #
#                              Outbreak Proportion                             #
# ---------------------------------------------------------------------------- #

### Minimum number of cases to be considered an outbreak
size = 100


"""
Returns whether the infection exceeds the specified size threshold.

Output: T/F
"""
function check_outbreak(traj, size)
    N = sum(traj[1,:])

    final_S = traj[end,:S]

    total = N - final_S

    return(total >= size)
end



function build_outbreak_data(file_addresses, j, size)
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
    T_str_raw = string(T_num)
    T_str_end = match(r"\(.+$", T_str_raw).match
    T_str = match(r"[^\(\)]+", T_str_end).match
    
    ### Create row vector of parameter values
    pars = Array{Any}(undef, 1, p)
    for i in 1:(p - 1)
        pars[i] = pars_raw[i]
    end
    pars[end] = T_str


    ### Get proportion of outbreaks
    all_outbreak_checks = check_outbreak.(info, size)
    outbreak_prop = mean(all_outbreak_checks)

### Create row vector for data frame
    outbreak_vector = Array{Any}(undef, 1, p + 1)
    outbreak_vector[1:(end - 1)] = pars
    outbreak_vector[end] = outbreak_prop

### Create data frame for outbreak
    outbreak_col_names = deepcopy(parameter_names)
    push!(outbreak_col_names, :Proportion)
    outbreak_data =  DataFrame(outbreak_vector, outbreak_col_names)

    outbreak_data
end



all_outbreak_data_pieces = @showprogress [build_outbreak_data(file_addresses, i, size) for i in eachindex(file_addresses) ]

outbreak_data = all_outbreak_data_pieces[1]
for i in 2:length(all_outbreak_data_pieces)
    append!(outbreak_data, all_outbreak_data_pieces[i])
end

CSV.write("Data/Output/All_Outbreak_Proportions.csv", outbreak_data)