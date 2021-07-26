using Plots
using Random, Distributions # For Update_Functions.jl
using DataFrames, CSV # For Read_Data.jl


Random.seed!(21131346)
const M = 10 # Number of times to replicate each parameter combination


#############################
### Initialize parameters ###
#############################

n_days = 90 # Number of days in a term. This might change between terms
const week_length = 7

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
include("Read_Data.jl"); # This must be run after initializing parameters so that classwise risks can be computed

######################
### Run Simulation ###
######################

status = read_data("Data/Small-Data.csv")

all_sim_outputs = [run_sim(status, n_initial_cases, n_days) for i in 1:M]

##################################
### Process simulation results ###
##################################

sim_output = all_sim_outputs[1]

S_traj = compartment_trajectory(sim_output, "S")
E_traj = compartment_trajectory(sim_output, "E")
A_traj = compartment_trajectory(sim_output, "A")
I_traj = compartment_trajectory(sim_output, "I")
R_traj = compartment_trajectory(sim_output, "R")


plotly()

p = plot(0:n_days, S_traj, label = "S");
plot!(p, 0:n_days, E_traj, label = "E");
plot!(p, 0:n_days, A_traj, label = "A");
plot!(p, 0:n_days, I_traj, label = "I");
plot!(p, 0:n_days, R_traj, label = "R");
plot(p)