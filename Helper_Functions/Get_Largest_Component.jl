

using LightGraphs   # For graph functions

"""
If not already accounted for, enroll student i in class j.
"""
function enroll!(enrollment, i, j)
    this_pos = enrollment[i,j]
    this_pos == 0 ? enrollment[i,j] = 1 : nothing
end



"""
Construct the enrollment matrix corresponding to the provided status object.
"""
function build_enrollment(status)
    num_students = length(status["students"])
    num_classes = length(status["classes"])
    enrollment = zeros(num_students, num_classes)

    for i in 1:num_students
        this_student = status["students"][i]
        this_classes = this_student["classes"]
        
        for j in this_classes
            enroll!(enrollment, i, j)
        end
    end

    return enrollment
end

"""
Construct the student-by-student adjacency matrix.
"""
function student_by_student(enrollment)
    student_adj_raw = enrollment * enrollment'
    student_adj = sign.(student_adj_raw)    # We want indicators, not counts
end


function get_largest_component(student_adj)
    student_graph = Graph(student_adj)  # More edges than rows in dataset because adding  
                                        # one student to a class of 100 adds 100 edges
    
    all_components = connected_components(student_graph)
    component_lengths = length.(all_components)
    
    ind_max = findmax(component_lengths)[2]
    largest_component = all_components[ind_max]
end




"""
Delete any students outside of the largest connected component.
"""
function delete_isolated_components!(status)
    enrollment = build_enrollment(status)
    
    student_adj = student_by_student(enrollment)

    largest_component = get_largest_component(student_adj)
    
    num_students = length(status["students"])
    students_to_delete = filter(x -> !(x ∈ largest_component), 1:num_students)

    delete_student_list!(status, students_to_delete)
    
    return status
end
