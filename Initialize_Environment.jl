
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


include("Helper_Functions.jl");



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
if !@isdefined all_thresholds; const all_thresholds = [20, 50, 100, ∞]; end # Maximum class sizes


# ----------- Container for all combinations of varying parameters ----------- #
if !@isdefined all_parameters; const all_parameters = expand_grid(all_infect_prop_A, all_infect_prop_I1, all_infect_param_I2, all_advance_prob_E,
    all_advance_prob_A, all_advance_prob_I1, all_advance_prob_I2, all_E_to_A_prob, all_thresholds); end


