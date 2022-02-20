
using DataFrames
using JLD2
using Infinity
using ProgressMeter
using Pipe

if !@isdefined all_thresholds; const all_thresholds = [20, 50, 100, ∞]; end # Maximum class sizes


file_list = readdir("Data/From Cluster/Objects")
file_addresses = "Data/From Cluster/Objects/" .* file_list

output_file_list = readdir("Data/Objects/M=10")
output_addresses = "Data/Objects/M=10/" .* output_file_list


# data = load(file_addresses[1])
# all_sim_outputs = data["all_sim_outputs"][a:b]
# all_parameters = data["all_parameters"][a:b]



"""
    Compute the number of non-S, non-R individuals at the end of the simulation.
    Takes sim_output as a data frame.
"""
function terminal_case_count(sim_output::AbstractDataFrame)
    @pipe sim_output |> 
    select(_, Not([:S, :R])) |> # Get diseased compartments
    _[end,:] |>                 # Extract final counts
    sum(_)                      # Compute total number of cases at termination
end

"""
    Compute the number of non-S, non-R individuals at the end of the simulation.
    Takes a vector containing the relevant data frame as its first entry.
"""
function terminal_case_count(sim_output::AbstractVector)
    @pipe sim_output |> 
    _[1] |>                     # Extract the data frame
    select(_, Not([:S, :R])) |> # Get diseased compartments
    _[end,:] |>                 # Extract final counts
    sum(_)                      # Compute total number of cases at termination
end

"""
    Compute the number of recovered individuals at the end of the simulation.
    Takes the data frame itself.
"""
function terminal_recs_count(sim_output::AbstractDataFrame)
    @pipe sim_output |> 
    select(_, :R) |>            # Get recovered compartment
    _[end,:] |>                 # Extract final counts
    sum(_)                      # Compute total number of cases at termination
end

# ---------------------------------------------------------------------------- #
#        Find number of cases at end of simulation within each threshold       #
# ---------------------------------------------------------------------------- #

# all_final_counts = Dict{Any, Any}()
# for thresh in all_thresholds
#     all_final_counts[thresh] = Vector{Any}()
# end

# ### Iterate over files
# # for i in eachindex(output_file_list)
# @showprogress for j in eachindex(output_file_list) 
#     this_address = "Data/Objects/M=10/p=" * string(j) * ".jld2"

#     this_info = load(this_address)
#     this_pars = this_info["parameters"]
#     this_data = this_info["output"]

#     final_counts = terminal_case_count.(this_data)

#     this_thresh = this_pars[end]
#     append!(all_final_counts[this_thresh], final_counts)
# end

# @save "Data/Objects/Final_Case_Counts.jld2" all_final_counts

@load "Data/Objects/Final_Case_Counts.jld2"


# ---------------------------------------------------------------------------- #
#                        Get final number of recovereds                        #
# ---------------------------------------------------------------------------- #

# all_final_recs = Dict{Any, Any}()
# for thresh in all_thresholds
#     all_final_recs[thresh] = Vector{Any}()
# end

# ### Iterate over files
# @showprogress for j in eachindex(output_file_list) 
#     this_address = "Data/Objects/M=10/p=" * string(j) * ".jld2"

#     this_info = load(this_address)
#     this_pars = this_info["parameters"]
#     this_data = this_info["output"]

#     final_recs = terminal_recs_count.(this_data)

#     this_thresh = this_pars[end]
#     append!(all_final_recs[this_thresh], final_recs)
# end

# @save "Data/Objects/Final_Recovereds_Counts.jld2" all_final_recs

@load "Data/Objects/Final_Recovereds_Counts.jld2"


# ---------------------------------------------------------------------------- #
#                         Plot final compartment sizes                         #
# ---------------------------------------------------------------------------- #

using Plots

gr()

threshold_names = ("20", "50", "100", "∞")


# -------------------------------- Histograms -------------------------------- #
all_hists = Vector{Any}()
for i in eachindex(all_thresholds)
    thresh = all_thresholds[i]
    this_title = threshold_names[i]
    this_hist = histogram(all_final_counts[thresh], legend = false,
    title = this_title);
    push!(all_hists, this_hist)
end

plot(all_hists..., layout = (2,2))


# ----------------- Scatterplots of final cases vs recovereds ---------------- #
all_plots = Vector{Any}()
for i in eachindex(all_thresholds)
    thresh = all_thresholds[i]
    this_title = threshold_names[i]

    recs = all_final_recs[thresh]
    cases = all_final_counts[thresh]

    ### For threshold of 100, remove the one major stall
    if i==3
        to_keep = recs .> 2000
        recs = recs[to_keep]
        cases = cases[to_keep]
    end

    this_plot = scatter(recs, cases, xlabel = "Final Recovered Count", ylabel = "Final Active Cases", legend = false, 
    markersize = 1, title = this_title, xformatter=:plain)

    push!(all_plots, this_plot)
end

plot(all_plots..., layout = (2,2))



using Infinities
using Infinity


a = 1:5
b = 6:10
q = ∞

using Plots

plot(a, b, title = q)