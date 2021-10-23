
Random.seed!(21131346)

N_classes = 10
N_students = 50



# Choose randomly selected days for a class to meet
function meeting_days(week_length)
    n_meetings = sample(1:week_length, 1)[1]
    meetings = sample(1:week_length, n_meetings, replace=false)
end


"""
Generate a status object with the specified number of students and classes. Optionally, have all classes meet on day 1; otherwise meeting days are uniformly distributed.
"""
function make_status(N_students, N_classes, day_one = false)

##############################
### Construct all students ###
##############################

### Create random compartments
    this_compartments = sample(all_compartments, N_students, replace=true)

### Create random timetables
    all_num_classes = rand(Poisson(2), N_students) .+ 1 # Number of classes in which each student is enrolled
    a_student_classes(n) = sample(1:N_classes, n, replace=false) # Need to apply this function over all_num_classes
    all_students_classes = a_student_classes.(all_num_classes) # Indices of classes in which each student is enrolled

### Construct vector of students using array comprehension
    students = [Dict("compartment" => this_compartments[i], "classes" => all_students_classes[i]) for i in 1:N_students]


#############################
### Construct all classes ###
#############################

# Note: Classes have already been determined by constructing students. We just need to extract the class info



### Create empty classes using array comprehension
    all_classes = [Dict("size" => 0, "S" => Vector{Int}(), "E" => Vector{Int}(), "A" => Vector{Int}(), "I1" => Vector{Int}(),
                "I2" => Vector{Int}(), "R" => Vector{Int}(), "days" => Vector{Int}()) for i in 1:N_classes]

    # ----------------------------- Add meeting days ----------------------------- #
    if day_one
        for i in eachindex(all_classes)
            all_classes[i]["days"] = 1
        end
    else
        for i in eachindex(all_classes)
            all_classes[i]["days"] = meeting_days(week_length)
        end
    end


# -------------------------- Create and add students ------------------------- #
    for i in 1:N_students
        this_student = students[i]
        this_compartment = this_student["compartment"]
        this_classes_ind = this_student["classes"]
        this_classes = all_classes[this_classes_ind]

        add_student!.(this_classes, i, this_compartment)
    end

#= 
### Check to make sure that all classes have the correct size
function size_check(class)
    size = class["size"]

    compartments_dict = filter(pair -> pair.first != "size", class)
    compartments = collect(values(compartments_dict))
    size_hat = sum(length.(compartments))

    size == size_hat
end

minimum(size_check.(all_classes)) =#


### Add infection risk to each class, defined as the probability of a single S being infected by any of the As or Is


    compute_risk!.(all_classes, infect_param_A, infect_param_I1, infect_param_I2);


### Construct status object
    status = Dict("classes" => all_classes, "students" => students)
end


status = make_status(N_students, N_classes, true)
status_new = deepcopy(status)
status_old = deepcopy(status)


#=
### Test update function
status1 = deepcopy(status)

a_class = deepcopy(status1["classes"][1])
#one_step!(status1, infect_param_A, infect_param_I, advance_prob_E, E_to_A_prob, recovery_prob_A, recovery_prob_I)
one_step!(status1)
a_class_again = status1["classes"][1]

println(a_class)
println(a_class_again)
=#