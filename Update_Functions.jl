using Random, Distributions

include("Helper_Functions.jl")

#############################################
###    Begin defining update functions    ###
#############################################

function update_S!(status_new, status_old)
    # Extract info on current status
    classes_old = status_old["classes"]

    for i in eachindex(classes_old)
        this_class = classes_old[i]
        this_S = this_class["S"]
        this_risk = this_class["risk"]

        # Get number of new exposeds
        n_S = length(this_S)
        if n_S == 0
            continue # Skip this iteration if no susceptibles remain
        end
        this_binom = Binomial(n_S, this_risk)
        n_new_cases = rand(this_binom, 1)[1] # Need output to be a scalar, not a length 1 vector

        if n_new_cases == 0
            continue # Skip the rest of this iteration if no new cases arise
        end

        # Choose specific new exposeds
        which_new_cases = sample(this_S, n_new_cases, replace=false)

        # Move new infections to the "E" compartment
        # Note: The . applies this function over the vector which_new_cases
        change_compartment!.(Ref(status_new), which_new_cases, "E")
    end
end

# Moves some fraction of Es to A and/or I.
# Changes are made in status_new, values for computation are obtained from status_old.
# advance_prob_E is the day-wise probability of an E moving to some other compartment
# E_to_A_prob is the proportion of transitions out of E which are to A (the rest go to I)
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
    # WARNING: We are sampling indices to students, not indices to inds_E
    which_to_transition = sample(inds_E, n_leaving, replace = false)

    # Choose how many of the transitions are to A and I
    binom_to_A = Binomial(n_leaving, E_to_A_prob)
    n_to_A = rand(binom_to_A, 1)[1] 
    n_to_I = n_leaving - n_to_A

    # Choose individuals and perform transitions to A
    if n_to_A != 0
        which_to_A = sample(which_to_transition, n_to_A, replace = false)
        change_compartment!.(Ref(status_new), which_to_A, "A")
    else
        # Even if no transitions to A occur, still create an empty container so we can do 
        # set arithmetic to get indices transitioning to I
        which_to_A = Vector{Int64}()
    end

    # Choose individuals and perform transitions to I
    if n_to_I != 0
        which_to_I = setdiff(which_to_transition, which_to_A)
        change_compartment!.(Ref(status_new), which_to_I, "I")
    end
end

# Moves some fraction of Es to A and/or I.
# Changes are made in status_new, values for computation are obtained from status_old.
# advance_prob_E is the day-wise probability of an E moving to some other compartment
# E_to_A_prob is the proportion of transitions out of E which are to A (the rest go to I)
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
    # WARNING: We are sampling indices to students, not indices to inds_E
    which_to_transition = sample(inds_E, n_leaving, replace = false)

    # Choose how many of the transitions are to A and I
    binom_to_A = Binomial(n_leaving, E_to_A_prob)
    n_to_A = rand(binom_to_A, 1)[1] 
    n_to_I = n_leaving - n_to_A

    # Choose individuals and perform transitions to A
    if n_to_A != 0
        which_to_A = sample(which_to_transition, n_to_A, replace = false)
        change_compartment!.(Ref(status_new), which_to_A, "A")
    else
        # Even if no transitions to A occur, still create an empty container so we can do 
        # set arithmetic to get indices transitioning to I
        which_to_A = Vector{Int64}()
    end

    # Choose individuals and perform transitions to I
    if n_to_I != 0
        which_to_I = setdiff(which_to_transition, which_to_A)
        change_compartment!.(Ref(status_new), which_to_I, "I")
    end
end

# Moves some fraction of As to R.
# Changes are made in status_new, values for computation are obtained from status_old.
# recovery_prob_A is the probability of a particular asymptomatic recovering on a specific day
function update_A!(status_new, status_old, recovery_prob_A)
    students_old = status_old["students"]

    # We only need the indices of the students in A. Extract these indices here
    inds_A = get_compartments(students_old, "A")

    # Get number transitioning out out of A
    n_A = length(inds_A)
    if n_A == 0
        return nothing # End the process if there are no exposeds
    end
    this_binom = Binomial(n_A, recovery_prob_A)
    n_leaving = rand(this_binom, 1)[1] # Need output to be a scalar, not a length 1 vector

    if n_leaving == 0
        return nothing # End the process here if no transitions occur
    end

    # Choose specific individuals to transition out of A
    # WARNING: We are sampling indices to students, not indices to inds_A
    which_to_transition = sample(inds_A, n_leaving, replace = false)

    # Update status_new
    change_compartment!.(Ref(status_new), which_to_transition, "R")
end

# Moves some fraction of Is to R.
# Changes are made in status_new, values for computation are obtained from status_old.
# recovery_prob_I is the probability of a particular asymptomatic recovering on a specific day
function update_I!(status_new, status_old, recovery_prob_I)
    students_old = status_old["students"]

    # We only need the indices of the students in I. Extract these indices here
    inds_I = get_compartments(students_old, "I")

    # Get number transitioning out out of I
    n_I = length(inds_I)
    if n_I == 0
        return nothing # End the process if there are no exposeds
    end
    this_binom = Binomial(n_I, recovery_prob_I)
    n_leaving = rand(this_binom, 1)[1] # Need output to be a scalar, not a length 1 vector

    if n_leaving == 0
        return nothing # End the process here if no transitions occur
    end

    # Choose specific individuals to transition out of I
    # WARNING: We are sampling indices to students, not indices to inds_I
    which_to_transition = sample(inds_I, n_leaving, replace = false)

    # Update status_new
    change_compartment!.(Ref(status_new), which_to_transition, "R")
end

# Re-compute risks for each class and update the class objects
function update_risk!(status_new, infect_param_A, infect_param_I)
    classes = status_new["classes"]

    # Compute and store new classwise risks
    compute_risk!.(classes, infect_param_A, infect_param_I)
end


# Runs a single time step and update status with parameters defined explicitly
function one_step!(status, infect_param_A = infect_param_A, infect_param_I = infect_param_I, 
    advance_prob_E = advance_prob_E, E_to_A_prob = E_to_A_prob, 
    recovery_prob_A = recovery_prob_A, recovery_prob_I = recovery_prob_I)
    status_new = status
    status_old = deepcopy(status)

    update_S!(status_new, status_old)
    update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)
    update_A!(status_new, status_old, recovery_prob_A)
    update_I!(status_new, status_old, recovery_prob_I)
    
    update_risk!(status_new, infect_param_A, infect_param_I)

    status = status_new
end

#=
# Runs a single time step and update status with parameters drawn from global scope
function one_step!(status)
    status_new = status
    status_old = deepcopy(status)

    update_S!(status_new, status_old)
    update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)
    update_A!(status_new, status_old, recovery_prob_A)
    update_I!(status_new, status_old, recovery_prob_I)
    
    update_risk!(status_new, infect_param_A, infect_param_I)

    status = status_new
end
=#