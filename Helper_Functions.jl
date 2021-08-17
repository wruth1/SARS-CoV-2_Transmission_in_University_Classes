#########################
### Edit compartments ###
#########################

# Find all students in compartment X
# If output = "indices", return the students' indices in students
# If output = "students", return the student objects
function get_compartments(students, X, output="indices")
    if output == "indices"
        findall(w -> w["compartment"] == X, students)
        
    elseif output == "students"
        filter(w -> w["compartment"] == X, students)
    end
end

# Move student i to compartment_new and update status
function change_compartment!(status, ind_student, compartment_new)
    students = status["students"]
    this_student = students[ind_student]
    this_student_classes = this_student["classes"]
    compartment_old = this_student["compartment"]

    classes = status["classes"][this_student_classes]

    ### Remove this student from their old compartment and add them to their new compartment
    for this_class in classes

        this_compartment_old = this_class[compartment_old]
        this_compartment_new = this_class[compartment_new]

        # Remove this student from their old compartment
        filter!(x -> x != ind_student, this_compartment_old)

        # Add this student to their new compartment
        push!(this_compartment_new, ind_student)
    end

    # Update this student's compartment
    this_student["compartment"] = compartment_new
end


############################
### Edit Classwise Risks ###
############################

# Compute the probability of transmission along a single pair with the transmitter having the given proportionality constant
function transmit_prob(class_size, infect_param)
    if infect_param > 1
        @warn "Large infectiousness parameter of $infect_param may lead to problems"
    end
    prob = infect_param / sqrt(class_size)
    if prob > 1
        throw(DomainError("Infectiousness parameter is too large: transmission probability greater than 1"))
    end
    prob
end

# Compute risk of a single class
function class_risk(class, infect_param_A, infect_param_I)
    size = class["size"]
    p_A = transmit_prob(size, infect_param_A)
    p_I = transmit_prob(size, infect_param_I)

    n_A = length(class["A"])
    n_I = length(class["I"])

    # Probability of no infection from the specified compartment
    contrib_A = (1 - p_A)^n_A
    contrib_I = (1 - p_I)^n_I

    risk = 1 - contrib_A * contrib_I
end


### Incorporate the computed risk into the class
### Note: can also be used to update the class risk if number of As or Is has changed
function compute_risk!(class, infect_param_A, infect_param_I)
    class["risk"] = class_risk(class, infect_param_A, infect_param_I)
end


###########################################
### Extract information from simulation ###
###########################################

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
trajectory_summaries(all_sim_outputs)

Summarizes every compartment using function f. Specifically, for every compartment, 
    f is applied at each time step to all counts of the compartment.

Output: A data frame with rows indexing time and columns indexing compartments.

# Example
```
trajectory_summaries(all_sim_output, mean) # compute average trajectories
```
"""
function trajectory_summaries(all_sim_outputs, f)
    @pipe all_compartments |>
        map(X -> compartment_trajectory_summary(all_sim_outputs, X, f), _) |>   # Apply f to each compartment
        reduce(hcat, _) |>                                                      # Staple summaries together
        DataFrame(_, all_compartments)                                          # Convert result to a data frame
end

#####################################################################
### Building our objects after importing the data from a CSV file ###
#####################################################################


### Get all indices in parent_list which correspond to an element of list
function get_indices(list, parent_list)
    findall(x -> in(x, list), parent_list)
end

### Build a student object
### Course ids are required so that we can add the indices of the enrolled classes instead of their ids
function make_student(data, stu_id, crs_ids)
    ### Get ids of classes in which this student is enrolled
    this_entries = filter(row -> row.anonymized_emplid == stu_id, data)
    this_classes = this_entries.Anonymized_Crs_ID

    ### Convert class ids to indices
    this_class_indices = get_indices(this_classes, crs_ids)

    ### Construct the student object with initial compartment "S"
    this_student = Dict("compartment" => "S", "classes" => this_class_indices)
end


### Initialize a class object for the course with the specified id
### I.e. Find days on which it meets, create empty compartments and set size to 0
function make_empty_class(data, crs_id)
    class = Dict()
    
    ### Get the days on which the class meets
    this_entries = filter(row -> row.Anonymized_Crs_ID == crs_id, data)
    an_entry = this_entries[1,:]
    days_vec = Vector(an_entry[[:MON, :TUES, :WED, :THURS, :FRI, :SAT, :SUN]])
    days = findall(x -> x == 1, days_vec)
    class["days"] = days

    ### Create empty compartments
    for X in all_compartments
        class[X] = Vector{Int64}()
    end

    ### Initialize class size
    class["size"] = 0

    class
end
    

### Adds student number ind_student with the specified compartment to class
function add_student!(class, ind_student, compartment)
    class["size"] += 1
    push!(class[compartment], ind_student)
end


### Adds the supplied student object with index i to all of their classes
function incorporate_student!(classes, student, i)
    this_compartment = student["compartment"]
    class_inds = student["classes"]
    this_classes = classes[class_inds]
    add_student!.(this_classes, i, this_compartment)
end

### Adds all students to their classes
function incorporate_all_students!(classes, students)
    for i in eachindex(students)
        this_student = students[i]
        incorporate_student!(classes, this_student, i)
    end
end


# ---------------------------------------------------------------------------- #
#                Remove all classes above a specified threshold                #
# ---------------------------------------------------------------------------- #

"""
    get_class_sizes(status)

Get all class sizes.
"""
function get_class_sizes(status)
    map(X -> X["size"], status["classes"])
end

"""
Remove class i from the provided student, making sure to adjust indices of other classes as appropriate.
"""
function remove_class_from_student!(student, i)
    this_classes = student["classes"]
    # Remove class i if present
    filter!(X -> X != i, this_classes) ###! Warning: i is an index to the classes component of status, not to this_classes
    # Subtract 1 from class indices if larger than i
    map!(x -> x > i ? x - 1 : x, this_classes, this_classes)

    return student
end


"""
Remove class i from status, including from all students.
"""
function remove_class!(status, i)
    classes = status["classes"]
    students = status["students"]

    # Remove class i from classes
    deleteat!(classes, i)

    # Remove class i from students
    remove_class_from_student!.(students, i)

    return status
end

"""
Remove all classes from status with size greater than the specified threshold.
"""
function remove_large_classes!(status, threshold) 
    classes = status["classes"]
    to_remove = findall(X -> X["size"] > threshold, classes)

    for i in reverse(to_remove) ### Removing classes in recreasing order avoids each iteration ruining subsequent indices
        remove_class!(status, i)
    end
end




# ---------------------------------------------------------------------------- #
#                           General utility functions                          #
# ---------------------------------------------------------------------------- #

"""
Create a vector containing all combinations of elements in arguments. Takes any number of arguments.

Note: This is the same as the expand.grid function in R.
"""
function expand_grid(X...)
    vec(collect(Base.product(X...)))
end
