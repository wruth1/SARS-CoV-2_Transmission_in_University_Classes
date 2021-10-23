
#############################################
###    Begin defining update functions    ###
#############################################

# Generate indices of individuals leaving the susceptible compartment
function get_new_cases(class)
    this_risk = class["risk"]
    
    this_S = class["S"]
    n_S = length(this_S)

    # Skip this iteration if no susceptibles are present
    n_S != 0 ? nothing : return nothing # Structure is conditional ? true : false

    # Get number of new exposeds
    this_binom = Binomial(n_S, this_risk)
    n_new_cases = rand(this_binom, 1)[1] # Need output to be a scalar, not a length 1 vector

    # Skip the rest of this iteration if no new cases arise
    n_new_cases != 0 ? nothing : return nothing

    # Choose specific new exposeds
    which_new_cases = sample(this_S, n_new_cases, replace=false)
end

function update_S!(status_new, status_old, day)
    # Extract info on current status
    classes_old = status_old["classes"]

    for i in eachindex(classes_old)
        this_class = classes_old[i]

        # If this class doesn't meet on the specified day, skip to next iteration without any updating
        this_class_days = this_class["days"]
        in(day, this_class_days) ? nothing : continue # Structure is conditional ? true : false

        # Skip this iteration if no risk of infection
        this_risk = this_class["risk"]
        this_risk != 0 ? nothing : continue

        # Get indices of new exposeds
        new_cases = get_new_cases(this_class)

        # If no new cases are generated, move on to the next iteration
        isnothing(new_cases) ? continue : nothing

        # Move new infections to the "E" compartment
        # Note: The . applies this function over the vector which_new_cases
        change_compartment!.(Ref(status_new), new_cases, "E")
    end
end


# Moves some fraction of Es to I1 and/or A.
# Changes are made in status_new, values for computation are obtained from status_old.
# advance_prob_E is the day-wise probability of an E moving to some other compartment
# E_to_A_prob is the proportion of transitions out of E which are to A (the rest go to I1)
function update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)
    students_old = status_old["students"]

    # We only need the indices of the students in E. Extract these indices here
    inds_E = get_compartments(students_old, "E")

    # Get number transitioning out out of E
    n_E = length(inds_E)
    if n_E == 0
        return nothing # End the process if there are no exposeds
    end
    this_binom = Binomial(n_E, advance_prob_E)
    n_leaving = rand(this_binom, 1)[1] # Need output to be a scalar, not a length 1 vector

    if n_leaving == 0
        return nothing # End the process here if no transitions occur
    end

    # Choose specific individuals to transition out of E
    #! WARNING: We are sampling indices to students, not indices to inds_E
    which_to_transition = sample(inds_E, n_leaving, replace=false)

    # Choose how many of the transitions are to A and I1
    binom_to_A = Binomial(n_leaving, E_to_A_prob)
    n_to_A = rand(binom_to_A, 1)[1] 
    n_to_I1 = n_leaving - n_to_A

    # Choose individuals and perform transitions to A
    if n_to_A != 0
        which_to_A = sample(which_to_transition, n_to_A, replace=false)
        change_compartment!.(Ref(status_new), which_to_A, "A")
    else
        # Even if no transitions to A occur, still create an empty container so we can do 
        # set arithmetic to get indices transitioning to I1
        which_to_A = Vector{Int64}()
    end

    # Choose individuals and perform transitions to I1
    if n_to_I1 != 0
        which_to_I1 = setdiff(which_to_transition, which_to_A)
        change_compartment!.(Ref(status_new), which_to_I1, "I1")
    end
end


"""
    update_one_dest!(status_new, status_old, origin, dest, advance_prob)

Transition a random number of students from origin to dest compartments. Probability of an individual transitioning is advance_prob.

Note: We allow for the possibility of one student being selected to transition multiple times. In this case, we just transition them and ignore the multiplicity.
"""
function update_one_dest!(status_new, status_old, origin, dest, advance_prob)
    students_old = status_old["students"]

    # We only need the indices of the students in the origin compartment. Extract these indices here
    inds_orig = get_compartments(students_old, origin)

    # Get number transitioning out
    n_orig = length(inds_orig)
    if n_orig == 0
        return nothing # End the process if there are no students in the origin compartment
    end
    this_binom = Binomial(n_orig, advance_prob)
    n_leaving = rand(this_binom, 1)[1] # Need output to be a scalar, not a length 1 vector

    if n_leaving == 0
        return nothing # End the process here if no transitions occur
    end

    # Choose specific individuals to transition out
    # WARNING: We are sampling indices to students, not indices to inds_orig. Values of inds_origin correspond to indices to students
    which_to_transition = sample(inds_orig, n_leaving, replace=false)

    # Update status_new
    change_compartment!.(Ref(status_new), which_to_transition, dest)
end


function update_A!(status_new, status_old, advance_prob_A)
    update_one_dest!(status_new, status_old, "A", "R", advance_prob_A)
end

function update_I1!(status_new, status_old, advance_prob_I1)
    update_one_dest!(status_new, status_old, "I1", "I2", advance_prob_I1)
end

function update_I2!(status_new, status_old, advance_prob_I2)
    update_one_dest!(status_new, status_old, "I2", "R", advance_prob_I2)
end





# Re-compute risks for each class and update the class objects
function update_risk!(status_new, infect_param_A, infect_param_I1, infect_param_I2)
    classes = status_new["classes"]

    # Compute and store new classwise risks
    compute_risk!.(classes, infect_param_A, infect_param_I1, infect_param_I2)
end


# Runs a single time step and update status with parameters drawn from global scope
"""
    one_step!(status_new, status_old, day, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E, advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob)

Runs a single time step and update status_new using status_old as reference and parameters drawn from global scope

"""
function one_step!(status_new, status_old, day, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
    advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob)
    update_S!(status_new, status_old, day)
    update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)
    update_A!(status_new, status_old, advance_prob_A)
    update_I1!(status_new, status_old, advance_prob_I1)
    update_I2!(status_new, status_old, advance_prob_I2)
    
    update_risk!(status_new, infect_param_A, infect_param_I1, infect_param_I2)
end

"""
    one_term(status_initial, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E, advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_days)

Runs through a full term starting in status_initial and running for the specified number of days.

Output: A vector of compartment sizes.
"""
function one_term(status_initial, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
    advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_days)
    # Container to store all compartment counts
    trajectories = Array{Int64}(undef, n_days + 1, num_compartments)
    initial_counts = all_compartment_counts(status_initial)
    trajectories[1,:] = initial_counts

    day = 1

    # Initialize status_old
    status_old = status_initial

    for j ∈ 1:n_days
        # status_new = deepcopy(status_old) # This doesn't appear to be necessary, and takes a lot of time to run.
        status_new = status_old
        one_step!(status_new, status_old, day, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
        advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob)

        this_compartment_counts = all_compartment_counts(status_new)
        trajectories[j + 1,:] = this_compartment_counts

        status_old = status_new

        day = (day % week_length) + 1
    end

    trajectories
end


"""
    run_sim(status_raw, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E, advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_initial_cases, n_days)

    Create a copy of status, infect the specified number of initial cases, 
    then generate an infection trajectory and return it as a data frame.
"""
function run_sim(status_raw, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
    advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_initial_cases, n_days)
    this_status = deepcopy(status_raw)

    ### Introduce a few initial cases
    num_students = length(status_raw["students"])
    inds_infect = sample(1:num_students, n_initial_cases, replace=false)
    change_compartment!.(Ref(this_status), inds_infect, "I2")

    ### Compute classwise risks
    compute_risk!.(this_status["classes"], infect_param_A, infect_param_I1, infect_param_I2)


    trajectories_mat = one_term(this_status, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
    advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_days)
    trajectories_data = DataFrame(trajectories_mat, all_compartments)
end



"""
    one_parameter_set(status_raw, M, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E, advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_initial_cases, n_days)

Run M simulation replicates with the specified parameter values on the provided initialized status object.
"""
function one_parameter_set(status_raw, M, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
    advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_initial_cases, n_days)

    all_sim_outputs = Vector{Any}(undef, M)
    for i in 1:M
        all_sim_outputs[i] = run_sim(status_raw, infect_param_A, infect_param_I1, infect_param_I2, advance_prob_E,
        advance_prob_A, advance_prob_I1, advance_prob_I2, E_to_A_prob, n_initial_cases, n_days)
    end

    return all_sim_outputs
end


# all_risks = [this_status["classes"][i]["risk"] for i in eachindex(classes)]