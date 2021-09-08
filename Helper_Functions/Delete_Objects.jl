"""
    get_class_sizes(status)

Get all class sizes.
"""
function get_class_sizes(status)
    map(X -> X["size"], status["classes"])
end

"""
Removes i from X and decrement values in X greater than i.
"""
function delete_in_list!(X::AbstractVector{T}, i::T) where T<:Int
    @pipe X |>
    filter!(y -> y != i, _) |>
    map!(y -> y > i ? y-1 : y, _, _)
end


"""
Update the provided student to account for deleting class i. Specifically, remove class i and update indices of any classes after i.
"""
function delete_class_in_student(student, i)
    this_classes = student["classes"]
    
    delete_in_list!(this_classes, i)
end

"""
Update the provided class to account for deleting student i. Specifically, remove student i and update indices of any students after i.
"""
function delete_student_in_class!(class, i)
    for X in all_compartments
        delete_in_list!(class[X], i)
    end
end






"""
Remove class i from status, including from all students.
"""
function delete_class!(status, i)
    classes = status["classes"]
    students = status["students"]

    # Remove class i from classes
    deleteat!(classes, i)

    # Remove class i from students
    delete_class_in_student.(students, i)

    return status
end

"""
Remove student i from status, including from all classes.
"""
function delete_student!(status, i)
    classes = status["classes"]
    students = status["students"]

    # Remove student i from students
    deleteat!(students, i)

    # Remove student i from classes
    delete_student_in_class!.(classes, i)

    return status
end


"""
Delete all students in the provided list.

Note: Students must be deleted in descending index order.
"""
function delete_student_list!(status, student_list)
    for i in reverse(student_list)
        delete_student!(status, i)
    end

    return status
end


"""
Delete all classes in the provided list.

Note: Classes must be deleted in descending index order.
"""
function delete_class_list!(status, class_list)
    for i in reverse(class_list)
        delete_class!(status, i)
    end

    return status
end


"""
Delete students with no classes.
"""
function delete_isolated_students!(status)
    students_to_remove = findall(X -> isempty(X["classes"]), status["students"])

    delete_student_list!(status, students_to_remove)
end

"""
Delete classes with 1 or 0 students. Optionally, also remove students with no remaining classes.
"""
function delete_tiny_classes!(status, adjust_students=true)
    classes_to_remove = findall(X -> X["size"] <= 1, status["classes"])

    delete_class_list!(status, classes_to_remove)

    # ----------------- Remove students with no remaining classes ---------------- #
    if adjust_students; delete_isolated_students!(status); end
end


"""
Remove all classes from status with size greater than the specified threshold. 
Optionally, also remove students with no remaining classes.
"""
function delete_large_classes(status, threshold, adjust_students=true) 
    classes = status["classes"]
    students = status["students"]

    classes_to_remove = findall(X -> X["size"] > threshold, classes)

    delete_class_list!(status, classes_to_remove)

    # ----------------- Remove students with no remaining classes ---------------- #
    if adjust_students; delete_isolated_students!(status); end

end


