using Plots
using Random, Distributions # For Update_Functions.jl
using DataFrames, CSV # For Read_Data.jl
using Statistics # For faster computation of standard deviations
using ProgressMeter # To track progress for long loops
using Pipe # Improved pipe operator
using JLD # Save and load variables


Random.seed!(21131346)
M = 10 # Number of times to replicate each parameter combination

max_threads = Threads.nthreads()
num_threads = max_threads - 1 # Leave one thread available while code is running


#############################
### Initialize parameters ###
#############################

################################################! Fix errors with package loading
Pkg.up("Roots")
Pkg.up("StaticArrays")
Pkg.up("SentinelArrays")
Pkg.up("Clustering")
Pkg.up("StaticArrays")
Pkg.up("PlotlyJS")

Pkg.add("StaticArrays")
Pkg.add("SentinelArrays")
Pkg.add("Clustering")
Pkg.add("StaticArrays")
Pkg.add("PlotlyJS")
Pkg.add("PlotlyBase")

Pkg.precompile()

using Plotly
################################################!


const n_days = 90 # Number of days in a term. This might change between terms
const week_length = 7

const all_compartments = ["S", "E", "A", "I", "R"]
const num_compartments = length(all_compartments)

const all_infect_param_I = [0.1, 0.5, 1]
const all_infect_param_A = [0.5, 0.75, 1] .* all_infect_param_I'
const all_advance_prob_E = 1 ./ [4, 5.2, 6]
const all_E_to_A_prob = [0.16, 0.25, 0.5]
const all_disease_progress_prob = [0.5, 0.75, 0.9]
const all_recovery_prob_A = [1/5, 1/7, 1/9] .* all_disease_progress_prob'
const all_recovery_prob_I = [1/10, 1/11.8, 1/15]

#=
const infect_param_I = 1 # Proportionality constant for infection probability from symptomatic compartment
const infect_param_A = 0.75 * infect_param_I # Proportionality constant for infection probability from 
                                             # asymptomatic compartment (Johansson et al. 2021)
const advance_prob_E = 1/5.2 # Probability of an E moving to either A or I on a particular day (Li et al. 2020)
const E_to_A_prob = 0.16 # Probability that an advancement from E is to A (Byambasuren et al. 2020)
const disease_progress_prob = 0.5 # Probability of an A moving to I on a particular day (modified heavily from Anderson et al. 2021)
const recovery_prob_A = disease_progress_prob / 9 # Probability of an A moving to R on a particular day (One value from Public Health Ontatio 2021)
const recovery_prob_I = 1/11.8 # Probability of an I moving to R on a particular day (Public Health Ontario 2021)
=#
n_initial_cases = 10

### Useful global values
advance_prob_A = 1 - (1 - disease_progress_prob) * (1 - recovery_prob_A) # Probability of leaving A on a particular day
A_to_R_prob = recovery_prob_A / (disease_progress_prob + recovery_prob_A)       # Probability of moving to R conditional on leaving A



include("Helper_Functions.jl");
include("Update_Functions.jl");
include("Read_Data.jl"); 

######################
### Run Simulation ###
######################

### Raw status because it does not yet have classwise risks. 
### Either compute and store (slow), or read from disk (fast)
# status_raw = read_data("Data/2019-Fall.csv", false) 
# save("Data/Objects/Status_Raw.jld", "status_raw", status_raw)
status_raw = load("Data/Objects/Status_Raw.jld", "status_raw")

all_sim_outputs = one_parameter_set(status_raw, M, 
infect_param_A, infect_param_I, advance_prob_E, E_to_A_prob, recovery_prob_A, recovery_prob_I, n_initial_cases)

##################################
### Process simulation results ###
##################################

### Plot mean trajectory for I with uncertainty
I_means = compartment_trajectory_summary(all_sim_outputs, "I", mean)
I_sds = compartment_trajectory_summary(all_sim_outputs, "I", std)


gr()
plot(0:n_days, I_means, ribbon=I_sds, fillalpha=0.5, label="Mean I Trajectory with ± 1 SD")


### Plot mean trajectories for all compartments
mean_trajectories = trajectory_summaries(all_sim_outputs, mean)

plotly()
p = plot();
for X in all_compartments
    plot!(p, 0:n_days, mean_trajectories[:, X], label=X);
end
plot(p)



### Plot mean trajectories for all compartments with uncertainty
sd_trajectories = trajectory_summaries(all_sim_outputs, std)


gr()

p2 = plot();
for X in all_compartments
    plot!(p2, 0:n_days, mean_trajectories[:, X], ribbon=sd_trajectories[:, X], fillalpha=0.5, label=X);
end
plot(p2)


### Add vertical lines for weekends
Fridays = (0:5) * 7 .+ 5
Sundays = Fridays .+ 2
weekends = vcat(Fridays, Sundays)

vline!(p2, weekends, label="Weekends")