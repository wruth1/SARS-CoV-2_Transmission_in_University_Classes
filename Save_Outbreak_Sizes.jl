
# ------------ Get number of students affected in each simulation ------------ #
if !@isdefined average_disease_scopes
    average_disease_scopes = @showprogress [disease_scope(all_sim_outputs[i]) for i in eachindex(all_sim_outputs)]
end

# --------- Extract class size thresholds in plotting-friendly format -------- #
all_size_thresholds = map(X -> X[end], all_parameters)
string_thresholds = ["20" "50" "100" "∞"]
threshold_labels = ["A", "B", "C", "D"] # Letters to endure plots are ordered correctly
all_size_thresholds = Vector{Any}(undef, length(all_parameters))
for i in eachindex(all_size_thresholds)
    all_size_thresholds[i] = all_parameters[i][end]
end

# Convert from values to letters
for i in eachindex(all_thresholds)
    replace_in_list!(all_size_thresholds, all_thresholds[i], threshold_labels[i])
end


data = DataFrame(size = average_disease_scopes, threshold = all_size_thresholds)



# -------------------------- Get numbers of students ------------------------- #
all_Ns = string.([all_num_students[all_thresholds[i]] for i in eachindex(all_thresholds)])


# --------------------------------- Make Plot -------------------------------- #
gr()

plot_titles = "Threshold: " .* permutedims(string_thresholds, (2,1)) .* " (Max: " .* all_Ns .* ")"
plot_titles = permutedims(plot_titles, (2,1))

@df data histogram(:size, group=:threshold, layout=4,
size = (800, 500), title = plot_titles, label = nothing)



# ---------------------------------------------------------------------------- #
#                 Prepare scope data to pass to R for analysis                 #
# ---------------------------------------------------------------------------- #

# ------------- Get all outbreak sizes (instead of just averages) ------------ #
all_disease_scope_lists = all_outbreak_sizes(all_sim_outputs)
all_disease_scopes = nested2vec(all_disease_scope_lists)

scope_data = DataFrame(size = all_disease_scopes)


# ------------------------- Add class size thresholds ------------------------ #
thresholds_for_R = all_size_thresholds
for i in eachindex(threshold_labels)
    replace_in_list!(thresholds_for_R, threshold_labels[i], string_thresholds[i])
end
replace_in_list!(thresholds_for_R, "∞", "infinity")
scope_data[!, "threshold"] = repeat(thresholds_for_R, inner = M)


# ----------------- Convert parameter vector to a data frame ----------------- #
N = length(all_parameters)
p = length(all_parameters[1]) - 1 # We have already dealt with class size thresholds
# Store parameter values in a matrix
parameter_array = Array{Float64}(undef, N, p)
for i in 1:N
    to_insert = all_parameters[i][1:(end-1)]
    for j in 1:p
        parameter_array[i,j] = to_insert[j]
    end
end
# Add the matrix to our data frame column-by-column
par_names_string = string.(parameter_names)[1:p]
for i in eachindex(par_names_string)
    scope_data[!, par_names_string[i]] = repeat(parameter_array[:,i], inner = 2)
end

# --------------------------- Store our data frame --------------------------- #
CSV.write("Data/Output/Outbreak_Size/M=2.csv", scope_data)
