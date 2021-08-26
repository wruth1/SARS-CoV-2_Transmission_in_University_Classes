# Get the number of students in compartment X in the provided class
function classwise_compartment_count(class, X)
    length(class[X])
end


"""
    status_compartment_count(status, X)

Get the number of students in compartment X from the provided status object.
"""
function status_compartment_count(status, X)
    classes = status["classes"]
    size = @pipe classes |> 
           map(class -> class[X], _) |> # Extract compartment X
           reduce(vcat, _) |>           # Concatenate all classes' compartment X
           unique(_) |>                 # Retain only 1 copy of each student
           length(_)                    # Count number of distinct students
end

"""
    all_compartment_counts(status, compartments = all_compartments)

Finds the number of students in each specified compartment within the provided status object.
"""
function all_compartment_counts(status, compartments = all_compartments)
    all_counts = status_compartment_count.(Ref(status), compartments)
end

# Get the number of students in compartment X across time in the provided matrix of compartment counts
function compartment_trajectory(sim_output, X)

    all_sizes = status_compartment_count.(all_statuses, X)
    all_sizes
end



"""
    complete_compartment_trajectories(all_sim_outputs, X)

Extracts all trajectories for compartment X from all_sim_outputs.

Output: A matrix with rows indexing time and columns indexing simulation runs.
"""
function complete_compartment_trajectories(all_sim_outputs, X)
    @pipe all_sim_outputs |>
        map(sim_output -> sim_output[!,X], _) |>    # Extract trajectories for this compartment
        reduce(hcat, _)                             # Staple trajectories together
end


"""
    compartment_trajectory_summary(all_sim_outputs, X, f)

Applies function f at each time step to all counts of compartment X.

# Example
```
compartment_trajectory_summary(all_sim_output, "S", mean) # compute average trajectory for compartment S
```
"""
function compartment_trajectory_summary(all_sim_outputs, X, f)
    trajectories = complete_compartment_trajectories(all_sim_outputs, X)
    summary = [f(trajectories[i,:]) for i in 1:(n_days + 1)]
end


"""
trajectory_summaries(sim_outputs, f)

Summarizes every compartment using function f. Specifically, for every compartment, 
f is applied at each time step to all counts of the compartment.

Output: A data frame with rows indexing time and columns indexing compartments.

# Example
```
trajectory_summaries(sim_outputs, mean) # compute average trajectories
```
"""
function trajectory_summaries(sim_output, f)
    @pipe all_compartments |>
        map(X -> compartment_trajectory_summary(sim_output, X, f), _) |>       # Apply f to each compartment
        reduce(hcat, _) |>                                                      # Staple summaries together
        DataFrame(_, all_compartments)                                          # Convert result to a data frame
end

"""
Get the average number of people affected by the disease. I.e. Average of N - S_final 
"""
function average_outbreak_size(sim_output)
    mean_S_final =  @pipe sim_output |>
                    trajectory_summaries(_, mean) |>
                    X -> X[end, "S"]
    
    # ----------------------- Get total number of students ----------------------- #
    one_sim_output = sim_output[1]
    one_snapshot = one_sim_output[1,:]
    this_num_students = sum(one_snapshot)

    this_num_students - mean_S_final
end


function get_one_outbreak_size(trajectory)
    S_remaining = trajectory[end, "S"]
    N = sum(trajectory[1,:])
    return N - S_remaining
end

function get_outbreak_sizes(sim_output)
    get_one_outbreak_size.(sim_output)
end

function all_outbreak_sizes(all_sim_outputs)
    get_outbreak_sizes.(all_sim_outputs)
end