
using Plots             # For plotting
using Random            # For better sampling
using Distributions     # ?
using DataFrames        # For R-like data frames
using CSV               # For Read_Data.jl
using Statistics        # For faster computation of standard deviations
using ProgressMeter     # To track progress for long loops
using Pipe              # Improved pipe operator
using JLD2              # Save and load variables
using Infinity          # Adds the numbers ∞ and -∞
using StatsPlots        # For plotting variables in data frames
using LightGraphs       # For graph functions
using MatrixNetworks    # For graph functions on adjacency matrices *************** I don't think this one is needed
using SparseArrays      # For sparse matrix multiplication



Random.seed!(21131346)
M = 2 # Number of times to replicate each parameter combination


include("Helper_Functions.jl");

# ------------------------- Load pre-computed objects ------------------------ #
# @load "Data/Objects/Status_Raw.jld2"    # Status object without risks
@load "Data/Objects/All_Status_Raws.jld2"    # Status object without risks
@load "Data/Objects/M=2.jld2"           # Simulation results and matching parameter values


#############################
### Initialize parameters ###
#############################

parameter_names = (:infect_param_A, :infect_param_I, :advance_prob_E, :E_to_A_prob, :disease_progress_prob, 
                    :recovery_prob_A, :recovery_prob_I, :threshold)

# ----------------------------- Fixed parameters ----------------------------- #
if !@isdefined n_days; const n_days = 90; end # Number of days in a term. This might change between terms
if !@isdefined week_length; const week_length = 7; end
if !@isdefined all_compartments; const all_compartments = ["S", "E", "A", "I", "R"]; end
if !@isdefined num_compartments; const num_compartments = length(all_compartments); end

# -------------- Containers for parameters with multiple values -------------- #
if !@isdefined all_infect_param_I; const all_infect_param_I = [0.1, 0.5, 1]; end
if !@isdefined all_infect_param_A; const all_infect_param_A = [0.5, 0.75, 1] .* all_infect_param_I'; end
if !@isdefined all_advance_prob_E; const all_advance_prob_E = 1 ./ [4, 5.2, 6]; end
if !@isdefined all_E_to_A_prob; const all_E_to_A_prob = [0.16, 0.25, 0.5]; end
if !@isdefined all_disease_progress_prob; const all_disease_progress_prob = [0.5, 0.75, 0.9]; end
if !@isdefined all_recovery_prob_A; const all_recovery_prob_A = [1 / 5, 1 / 7, 1 / 9] .* all_disease_progress_prob'; end
if !@isdefined all_recovery_prob_I; const all_recovery_prob_I = [1 / 10, 1 / 11.8, 1 / 15]; end
if !@isdefined all_thresholds; const all_thresholds = [20, 50, 100, ∞]; end # Maximum class sizes


# ----------- Container for all combinations of varying parameters ----------- #
if !@isdefined all_parameters; const all_parameters = expand_grid(all_infect_param_I, all_infect_param_A, all_advance_prob_E,
    all_E_to_A_prob, all_disease_progress_prob, all_recovery_prob_A, all_recovery_prob_I, all_thresholds); end




    
#= 
const infect_param_I = 1 # Proportionality constant for infection probability from symptomatic compartment
const infect_param_A = 0.75 * infect_param_I # Proportionality constant for infection probability from 
                                             # asymptomatic compartment (Johansson et al. 2021)
const advance_prob_E = 1/5.2 # Probability of an E moving to either A or I on a particular day (Li et al. 2020)
const E_to_A_prob = 0.16 # Probability that an advancement from E is to A (Byambasuren et al. 2020)
const disease_progress_prob = 0.5 # Probability of an A moving to I on a particular day (modified heavily from Anderson et al. 2021)
const recovery_prob_A = disease_progress_prob / 9 # Probability of an A moving to R on a particular day (One value from Public Health Ontatio 2021)
const recovery_prob_I = 1/11.8 # Probability of an I moving to R on a particular day (Public Health Ontario 2021) =#
n_initial_cases = 10

# ### Useful global values
# advance_prob_A = 1 - (1 - disease_progress_prob) * (1 - recovery_prob_A) # Probability of leaving A on a particular day
# A_to_R_prob = recovery_prob_A / (disease_progress_prob + recovery_prob_A)       # Probability of moving to R conditional on leaving A





# ---------------------------------------------------------------------------- #
#                                Run Simulation                                #
# ---------------------------------------------------------------------------- #


# ---------- Read-in data and remove any classes with only 1 student --------- #
# --------- Raw status because it does not yet have classwise risks. --------- #
# --------- Either compute and store (slow), or read from disk (fast) -------- #
# ----------- Note: In latter case, only run if not already defined ---------- #
if (!@isdefined status_raw) & (!@isdefined all_status_raws)
    status_raw = read_data("Data/2019-Fall.csv", false) 
    delete_tiny_classes!(status_raw)
end



# ----------- Create status objects with different max class sizes ----------- #
# ------ Note: Functions to delete classes also delete isolated students ----- #
# ------------------ Note: Only runs if not already defined ------------------ #
if !@isdefined all_status_raws
    all_status_raws = Dict{Any,Any}()
    for thresh in all_thresholds
        println(thresh)
        
        this_status_raw = deepcopy(status_raw)

        # --------------------------- Remove large classes --------------------------- #
        delete_large_classes!(this_status_raw, thresh)
        delete_tiny_classes!(this_status_raw)   # Also remove any classes with 1 remaining student
        
        # ------------------ Extract the largest connected component ----------------- #
        delete_isolated_components!(this_status_raw);

        all_status_raws[thresh] = this_status_raw
    end

    @save "Data/Objects/All_Status_Raws.jld2" all_status_raws
end


# --------------------- Extract some useful global values -------------------- #
all_num_students = Dict{Any, Int16}()
all_num_classes = Dict{Any, Int16}()
for this_threshold in all_thresholds 
    this_status = all_status_raws[this_threshold]
    all_num_students[this_threshold] = length(this_status["students"])
    all_num_classes[this_threshold] = length(this_status["classes"])
end







# -------------- Pool of random seeds for use within simulation -------------- #
# ---- Note: UInt32 is 32-bit unsigned integer, represented in hexadecimal --- #
all_seeds = rand(UInt32, length(all_parameters))


# Container to store the output at each iteration
all_sim_outputs = Vector{Any}(undef, length(all_parameters))


# N = length(all_parameters)
N = 200
meter = Progress(N);    # Create progress meter
update!(meter, 0)       # Initialize progress of meter

# for ii in eachindex(all_parameters)
Threads.@threads for ii in 1:N
# for ii in 1:N

    # ----------------- Set seed locally for reproducible results ---------------- #
    this_seed = all_seeds[ii]
    Random.seed!(this_seed)

    # ---------------- Extract parameter values for this iteration --------------- #
    this_parameters = all_parameters[end - ii]

    infect_param_I = this_parameters[1]
    infect_param_A = this_parameters[2]
    advance_prob_E = this_parameters[3]
    E_to_A_prob = this_parameters[4]
    disease_progress_prob = this_parameters[5]
    recovery_prob_A = this_parameters[6]
    recovery_prob_I = this_parameters[7]
    threshold = this_parameters[8]

    this_status_raw = all_status_raws[threshold]
    advance_prob_A = 1 - (1 - disease_progress_prob) * (1 - recovery_prob_A)
    A_to_R_prob = recovery_prob_A / (disease_progress_prob + recovery_prob_A)


    # ------------------- Run this iteration and store results ------------------- #
    sim_outputs = one_parameter_set(this_status_raw, M, 
    infect_param_A, infect_param_I, advance_prob_E, E_to_A_prob, recovery_prob_I, advance_prob_A, A_to_R_prob, 
    n_initial_cases, n_days)

    all_sim_outputs[ii] = sim_outputs

    # ---------------------------- Update progress bar --------------------------- #
    next!(meter)
end

@save "Data/Objects/M=$M, N=$N.jld2"  all_sim_outputs all_parameters

