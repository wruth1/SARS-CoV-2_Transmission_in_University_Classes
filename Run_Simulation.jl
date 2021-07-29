using Plots
using Random, Distributions # For Update_Functions.jl
using DataFrames, CSV # For Read_Data.jl
using Statistics # For faster computation of standard deviations
using ProgressMeter # To track progress for long loops


Random.seed!(21131346)
M = 5 # Number of times to replicate each parameter combination


#############################
### Initialize parameters ###
#############################

const n_days = 90 # Number of days in a term. This might change between terms
const week_length = 7

const all_infect_param_As = ()

const infect_param_A = 1 # Proportionality constant for infection probability from asymptomatic compartment
const infect_param_I = 1 # Proportionality constant for infection probability from infected compartment
const advance_prob_E = 0.2 # Probability of an E moving to either A or I on a particular day
const E_to_A_prob = 0.5 # Probability that an advancement from E is to A
# const E_to_I_prob = 1 - E_to_A_prob # Probability that an advancement from E is to I 
const recovery_prob_A = 0.2 # Probability of an A moving to R on a particular day
const recovery_prob_I = 0.2 # Probability of an I moving to R on a particular day

n_initial_cases = 10


include("Helper_Functions.jl");
include("Update_Functions.jl");
include("Read_Data.jl"); 

######################
### Run Simulation ###
######################

### Raw status because it does not yet have classwise risks
status_raw = read_data("Data/2019-Fall.csv", false) 

all_sim_outputs = one_parameter_set(status_raw, M, 
infect_param_A, infect_param_I, advance_prob_E, E_to_A_prob, recovery_prob_A, recovery_prob_I, n_initial_cases)

### This line should be made redundant by the previous one.
# all_sim_outputs = [run_sim(status, n_initial_cases, n_days) for i in 1:M];

##################################
### Process simulation results ###
##################################

### Plot mean trajectory for I with uncertainty
all_I_trajs_raw = compartment_trajectory.(all_sim_outputs, "I")
all_I_trajs = [all_I_trajs_raw[i][j] for i in 1:M, j in 1:(n_days + 1)]

I_traj_summaries = trajectory_summary(all_I_trajs)
I_means = I_traj_summaries["means"]
I_sds = I_traj_summaries["sds"]


gr()
plot(0:n_days, I_means, ribbon = I_sds, fillalpha = 0.5, label = "Mean I Trajectory with ± 1 SD")


### Plot mean trajectories for all compartments
S_traj = mean_trajectory(all_sim_outputs, "S")
E_traj = mean_trajectory(all_sim_outputs, "E")
A_traj = mean_trajectory(all_sim_outputs, "A")
I_traj = mean_trajectory(all_sim_outputs, "I")
R_traj = mean_trajectory(all_sim_outputs, "R")


plotly()

p = plot(0:n_days, S_traj, label = "S");
plot!(p, 0:n_days, E_traj, label = "E");
plot!(p, 0:n_days, A_traj, label = "A");
plot!(p, 0:n_days, I_traj, label = "I");
plot!(p, 0:n_days, R_traj, label = "R");
plot(p)


### Plot mean trajectories for all compartments with uncertainty
S_sds = trajectory_sd(all_sim_outputs, "S")
E_sds = trajectory_sd(all_sim_outputs, "E")
A_sds = trajectory_sd(all_sim_outputs, "A")
I_sds = trajectory_sd(all_sim_outputs, "I")
R_sds = trajectory_sd(all_sim_outputs, "R")


gr()

p = plot(0:n_days, S_traj, ribbon = S_sds, fillalpha = 0.5, label = "S");
plot!(p, 0:n_days, E_traj, ribbon = E_sds, fillalpha = 0.5, label = "E");
plot!(p, 0:n_days, A_traj, ribbon = A_sds, fillalpha = 0.5, label = "A");
plot!(p, 0:n_days, I_traj, ribbon = I_sds, fillalpha = 0.5, label = "I");
plot!(p, 0:n_days, R_traj, ribbon = R_sds, fillalpha = 0.5, label = "R");
plot(p)


### Add vertical lines for weekends
Fridays = (0:5)*7 .+ 5
Sundays = Fridays .+ 2
weekends = vcat(Fridays, Sundays)

vline!(p, weekends, label = "Weekends")