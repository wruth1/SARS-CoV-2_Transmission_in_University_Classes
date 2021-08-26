
sim_outputs = all_sim_outputs[1]

### Plot mean trajectory for I with uncertainty
I_means = compartment_trajectory_summary(sim_outputs, "I", mean)
I_sds = compartment_trajectory_summary(sim_outputs, "I", std)


gr()
plot(0:n_days, I_means, ribbon=I_sds, fillalpha=0.5, label="Mean I Trajectory with ± 1 SD")


### Plot mean trajectories for all compartments
mean_trajectories = trajectory_summaries(sim_outputs, mean)

plotly()
p = plot();
for X in all_compartments
    plot!(p, 0:n_days, mean_trajectories[:, X], label=X);
end
plot(p)



### Plot mean trajectories for all compartments with uncertainty
sd_trajectories = trajectory_summaries(sim_outputs, std)


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