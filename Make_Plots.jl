
all_disease_scopes = @showprogress [disease_scope(all_sim_outputs[i]) for i in eachindex(all_sim_outputs)]

all_size_thresholds = map(X -> X[end], all_parameters)
string_thresholds = ["20" "50" "100" "∞"]
threshold_labels = ["A", "B", "C", "D"]
all_size_thresholds = Vector{Any}(undef, length(all_parameters))
for i in eachindex(all_size_thresholds)
    all_size_thresholds[i] = all_parameters[i][end]
end

for i in eachindex(all_thresholds)
    replace_in_list!(all_size_thresholds, all_thresholds[i], threshold_labels[i])
end


data = DataFrame(size = all_disease_scopes, threshold = all_size_thresholds)

gr()


# -------------------------- Get numbers of students ------------------------- #
all_Ns = string.([all_num_students[all_thresholds[i]] for i in eachindex(all_thresholds)])

plot_titles = "Threshold: " .* permutedims(string_thresholds, (2,1)) .* " (Max: " .* all_Ns .* ")"
plot_titles = permutedims(plot_titles, (2,1))

@df data histogram(:size, group=:threshold, layout=4,
size = (800, 500), title = plot_titles, label = nothing)
