#########################
### Edit compartments ###
#########################

# Find all students in compartment X
# If output = "indices", return the students' indices in students
# If output = "students", return the student objects
# ----------------------------------------------------------------------------------- Might be better to split this into two functions
function get_compartments(students, X, output = "indices")
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
        filter!(x -> x!=ind_student, this_compartment_old)

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
function add_risk!(class, infect_param_A, infect_param_I)
    class["risk"] = class_risk(class, infect_param_A, infect_param_I)
end