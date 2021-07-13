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