using Random, Distributions

include("Helper_Functions.jl")
include("Update_Functions.jl")

Random.seed!(21131346)

const N_classes = 10
const N_students = 50
const week_length = 7

const infect_param_A = 1 # Proportionality constant for infection probability from asymptomatic compartment
const infect_param_I = 1 # Proportionality constant for infection probability from infected compartment

const advance_prob_E = 0.2 # Probability of an E moving to either A or I on a particular day
const E_to_A_prob = 0.5 # Probability that an advancement from E is to A
# const E_to_I_prob = 1 - E_to_A_prob # Probability that an advancement from E is to I 
const recovery_prob_A = 0.2 # Probability of an A moving to R on a particular day
const recovery_prob_I = 0.2 # Probability of an I moving to R on a particular day

const days = 10 # Number of days in a term

#=
### Inefficient way to pass parameters. Put them in a container only to extract them again
const parameters = Dict(  "infect_param_A" => infect_param_A,
                    "infect_param_I" => infect_param_I,
                    "advance_prob_E" => advance_prob_E,
                    "E_to_A_prob" => E_to_A_prob,
                    "recovery_prob_A" => recovery_prob_A,
                    "recovery_prob_I" => recovery_prob_I)
=#


function make_status(N_students, N_classes)

##############################
### Construct all students ###
##############################

### Create random compartments
    all_compartments = sample(["S", "E", "A", "I", "R"], N_students, replace=true)

### Create random timetables
    all_num_classes = rand(Poisson(2), N_students) .+ 1 # Number of classes in which each student is enrolled
    a_student_classes(n) = sample(1:N_classes, n, replace=false) # Need to apply this function over all_num_classes
    all_students_classes = a_student_classes.(all_num_classes) # Indices of classes in which each student is enrolled

### Construct vector of students using array comprehension
    students = [Dict("compartment" => all_compartments[i], "classes" => all_students_classes[i]) for i in 1:N_students]


#############################
### Construct all classes ###
#############################

# Note: Classes have already been determined by constructing students. We just need to extract the class info

# Choose randomly selected days for a class to meet
function meeting_days(week_length)
    n_meetings = sample(1:week_length, 1)[1]
    meetings = sample(1:week_length, n_meetings, replace=false)
end

### Create empty classes using array comprehension
    all_classes = [Dict("size" => 0, "S" => Vector{Int}(), "E" => Vector{Int}(), "A" => Vector{Int}(), "I" => Vector{Int}(),
                "R" => Vector{Int}(), "days" => meeting_days(week_length)) for i in 1:N_classes]

    



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


    compute_risk!.(all_classes, infect_param_A, infect_param_I);


### Construct status object
    status = Dict("classes" => all_classes, "students" => students)
end

status = make_status(N_students, N_classes)
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