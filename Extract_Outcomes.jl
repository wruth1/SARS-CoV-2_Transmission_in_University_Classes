



#! I am currently getting an error caused by trying to convert ∞ into an integer. I can't build the parameter value data frame while this is happening



# ---------------------------------------------------------------------------- #
#                     Compute Outcome Measures of Interest                     #
# ---------------------------------------------------------------------------- #

# ------------------- Prepare list of files for reading-in ------------------- #
file_list = readdir("Data/Objects/M=10")
file_addresses = "Data/Objects/M=10/" .* file_list




# ---------------------------------------------------------------------------- #
#                              Total Outbreak Size                             #
# ---------------------------------------------------------------------------- #


function build_size_data(file_addresses, j)
    ### Read dataset and extract contents
    output = load(file_addresses[j])

    pars = output["parameters"]
    pars_vec = collect(pars)    # Convert from a tuple to an array
    info = output["output"]


### Extract some useful values
    M = length(info)    # Number of replicates
    p = length(pars)    # Number of parameters
    num_students = sum(info[1][1,:])


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


all_size_data = all_size_data_pieces[1]

for i in 2:length(all_size_data_pieces)
    this_size_data = vcat(all_size_data, all_size_data_pieces[i])
    global all_size_data = this_size_data
end

# for i in 2:length(file_addresses)
for i in 2:10
    this_size_data = build_size_data(file_addresses, i)
    global all_size_data = vcat(all_size_data, this_size_data)
end

q = build_size_data(file_addresses, 2)

vcat(all_size_data, q)