
###* The Infinities package is a better version of Infinity. In particular, Infinities doesn't print as an ugly string of type specifying code. I have stuck with the latter, uglier package for compatibility reasons, but if I rerun things it would be great to switch to Infinities.

using Plots             # For plotting
using Random            # For better sampling
using Distributions     # ?
using DataFrames        # For R-like data frames
using CSV               # For Read_Data.jl
using JLD2              # For storing and importing Julia objects using @save and @load
using Statistics        # For faster computation of standard deviations
using ProgressMeter     # To track progress for long loops
using Pipe              # Improved pipe operator
using Infinity          # Adds the numbers ∞ and -∞. Infinities is better but might not be compatible.
using StatsPlots        # For plotting variables in data frames
using LightGraphs       # For graph functions
using MatrixNetworks    # For graph functions on adjacency matrices *************** I don't think this one is needed
using SparseArrays      # For sparse matrix multiplication


target_enrollments = 32008  # Number of enrollments remaining after thresholding at 20
                            # Note: Excludes classes with single enrollment, but not isolated components

Random.seed!(21131346)
M = 10 # Number of times to replicate each parameter combination


include("Helper_Functions.jl");


# ------------------------- Load pre-computed objects ------------------------ #
@load "Data/Objects/All_Thinned_Status_Raws.jld2"   # Status object without risks


#############################
### Initialize parameters ###
#############################

parameter_names = [:infect_prop_A, :infect_prop_I1, :infect_param_I2, :advance_prob_E,
                    :advance_prob_A, :advance_prob_I1, :advance_prob_I2, :E_to_A_prob, :threshold];

# ----------------------------- Fixed parameters ----------------------------- #
if !@isdefined n_days; const n_days = 90; end # Number of days in a term. This might change between terms
if !@isdefined week_length; const week_length = 7; end
if !@isdefined all_compartments; const all_compartments = ["S", "E", "A", "I1", "I2", "R"]; end
if !@isdefined num_compartments; const num_compartments = length(all_compartments); end
if !@isdefined n_initial_cases; const n_initial_cases = 10; end

# -------------- Containers for parameters with multiple values -------------- #
# ---------- See ``Parameter Value Discussion'' document for details --------- #

# ------------- Proportion of infectiousness for A relative to I2 ------------ #
if !@isdefined all_infect_prop_A; const all_infect_prop_A = [0.4, 0.75, 1]; end
# ------------ Proportion of infectiousness for I1 relative to I2 ------------ #
if !@isdefined all_infect_prop_I1; const all_infect_prop_I1 = [0.18, 0.63, 2.26]; end
# -------------- Infectivity parameter for symptomatic infecteds ------------- #
if !@isdefined all_infect_param_I2; const all_infect_param_I2 = [0.141, 0.198, 0.240]; end
# ------------------------- Geometric parameter for E ------------------------ #
if !@isdefined all_advance_prob_E; const all_advance_prob_E = [0.168, 0.182, 0.196]; end
# ------------------------- Geometric parameter for A ------------------------ #
if !@isdefined all_advance_prob_A; const all_advance_prob_A = [0.115, 0.138, 0.169]; end
# ------------------------ Geometric parameter for I1 ------------------------ #
if !@isdefined all_advance_prob_I1; const all_advance_prob_I1 = [1/3, 0.435, 0.833]; end
# ------------------------ Geometric parameter for I2 ------------------------ #
if !@isdefined all_advance_prob_I2; const all_advance_prob_I2 = [0.063, 0.075, 0.092]; end
# --------------------- Proportion of asymptomatic cases --------------------- #
if !@isdefined all_E_to_A_prob; const all_E_to_A_prob = [0.09, 0.18, 0.26]; end

# ----------------------- Maximum in-person class size ----------------------- #
# ------- Note: Used to determine thinning level, not for thresholding ------- #
if !@isdefined all_thresholds; const all_thresholds = [20, 50, 100]; end


# ----------- Container for all combinations of varying parameters ----------- #
if !@isdefined all_parameters; const all_parameters = expand_grid(all_infect_prop_A, all_infect_prop_I1, all_infect_param_I2, all_advance_prob_E,
    all_advance_prob_A, all_advance_prob_I1, all_advance_prob_I2, all_E_to_A_prob, all_thresholds); end



[ns(all_thin_status_raws[thresh]) for thresh in all_thresholds]


# ---------------------------------------------------------------------------- #
#                                Run Simulation                                #
# ---------------------------------------------------------------------------- #



# ---------- Read-in data and remove any classes with only 1 student --------- #
# --------- Raw status because it does not yet have classwise risks. --------- #
# -- Only perform computations if not already defined (i.e. read from disk) -- #
if !@isdefined all_thin_status_raws
    # ------------- Get number of enrollments at each threshold level ------------ #
    @load "Data/Objects/All_Status_Raws.jld2"    # Full status object without risks
    include("Small_Scripts/Count_Enrollments.jl")   ########################################################################! Need to upload this file to cluster (maybe)

    include("Thinning_at_Random/Thin_Enrollments.jl")
    all_thin_status_raws = Dict(thresh => thin_data("Data/2019-Fall.csv", enrollment_counts[thresh], seed = 52501335) for thresh in all_thresholds)

    for thresh in all_thresholds
        delete_tiny_classes!(all_thin_status_raws[thresh])          # Remove classes with fewer than 2 students
        delete_isolated_components!(all_thin_status_raws[thresh])   # Remove isolated components
    end

    @save "Data/Objects/All_Thinned_Status_Raws.jld2" all_thin_status_raws
end


# --------------------- Extract some useful global values -------------------- #
all_num_students = Dict(thresh => ns(all_thin_status_raws[thresh]) for thresh in all_thresholds)
all_num_classes = Dict(thresh => nc(all_thin_status_raws[thresh]) for thresh in all_thresholds)


# -------------- Pool of random seeds for use within simulation -------------- #
# ---- Note: UInt32 is 32-bit unsigned integer, represented in hexadecimal --- #
all_seeds = rand(UInt32, length(all_parameters))


# Container to store the output at each iteration
all_sim_outputs = Vector{Any}(undef, length(all_parameters))



# ------------------------ Number of iterations to run ----------------------- #
# N = length(all_parameters)
N = 10
meter = Progress(N);    # Create progress meter
update!(meter, 0)       # Initialize progress of meter

# for ii in eachindex(all_parameters)
Threads.@threads for ii in 1:N

    # ----------------- Set seed locally for reproducible results ---------------- #
    this_seed = all_seeds[ii]
    Random.seed!(this_seed)

    # ---------------- Extract parameter values for this iteration --------------- #
    this_parameters = all_parameters[ii]

    infect_prop_A = this_parameters[1]
    infect_prop_I1 = this_parameters[2]
    infect_param_I2 = this_parameters[3]
    advance_prob_E = this_parameters[4]
    advance_prob_A = this_parameters[5]
    advance_prob_I1 = this_parameters[6]
    advance_prob_I2 = this_parameters[7]
    E_to_A_prob = this_parameters[8]
    threshold = this_parameters[9]


    this_status_raw = all_thin_status_raws[threshold]


    # -------------- Compute infectiousness parameters for I1 and A -------------- #
    infect_param_A = infect_prop_A * infect_param_I2
    infect_param_I1 = infect_prop_I1 * infect_param_I2

    # ------------------- Run this iteration and store results ------------------- #
    sim_outputs = one_parameter_set(this_status_raw, M, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
    advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_initial_cases, n_days)

    all_sim_outputs[ii] = sim_outputs

    # ---------------------------- Update progress bar --------------------------- #
    next!(meter)
end

# @save "Data/Objects/Thinned - M=$M, N=$N.jld2"  all_sim_outputs all_parameters

