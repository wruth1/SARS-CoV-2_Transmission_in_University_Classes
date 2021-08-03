#########################
### Edit compartments ###
#########################

# Find all students in compartment X
# If output = "indices", return the students' indices in students
# If output = "students", return the student objects
# ----------------------------------------------------------------------------------- Might be better to split this into two functions
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
           map(class -> class[X], _) |>
           reduce(vcat, _) |>
           unique(_) |>
           length(_)
end

"""
    all_compartment_counts(status, compartments = ["S", "E", "A", "I", "R"])

Finds the number of students in each specified compartment within the provided status object.
"""
function all_compartment_counts(status, compartments = ["S", "E", "A", "I", "R"])
    all_counts = status_compartment_count.(Ref(status), compartments)
end

# Get the number of students in compartment X across time in the provided sequence of status objects
function compartment_trajectory(all_statuses, X)
    all_sizes = status_compartment_count.(all_statuses, X)
    all_sizes
end

### Takes an array of trajectories and returns the mean and SD trajectories
### Rows index replicates, columns index days
function trajectory_summary(all_trajs)
    mean_trajs = zeros(n_days + 1)
    sd_trajs = zeros(n_days + 1)
    for i in 1:(n_days + 1)
        this_vals = all_trajs[:,i]

        this_mean = mean(this_vals)
        mean_trajs[i] = this_mean

        sd_trajs[i] = stdm(this_vals, this_mean)
    end
    
    Dict("means" => mean_trajs, "sds" => sd_trajs)
end

"""
    mean_trajectory(all_sim_outputs, compartment)

Get the mean trajectory for the specified compartment across all simulation runs.


"""
function mean_trajectory(all_sim_outputs, compartment)
    all_trajs_raw = compartment_trajectory.(all_sim_outputs, compartment)
    all_trajs = [all_trajs_raw[i][j] for i in 1:M, j in 1:(n_days + 1)]
    
    traj_summaries = trajectory_summary(all_trajs)
    traj_means = traj_summaries["means"]
end


"""
trajectory_sd(all_sim_outputs, compartment)

Get the pointwise sd of the trajectories for the specified compartment across all simulation runs.
"""
function trajectory_sd(all_sim_outputs, compartment)
    all_trajs_raw = compartment_trajectory.(all_sim_outputs, compartment)
    all_trajs = [all_trajs_raw[i][j] for i in 1:M, j in 1:(n_days + 1)]
    
    traj_summaries = trajectory_summary(all_trajs)
    traj_sds = traj_summaries["sds"]
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
    class["S"] = Vector{Int64}()
    class["E"] = Vector{Int64}()
    class["A"] = Vector{Int64}()
    class["I"] = Vector{Int64}()
    class["R"] = Vector{Int64}()

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














##########################
### Here be dragons!!! ###
##########################

### Trying to write a function which takes a variable and adds its value to a dictionary with key equal to the variable's name
### This doesn't seem like a thing anyone wants to do

#= 
# A macro which returns the name of an object
macro get_name(x)
    string(x)
end

function push_dict!(x)

    name = @get_name($x)
    name
end

function f()
    Main.@locals()
end

f(x) = @locals() =#