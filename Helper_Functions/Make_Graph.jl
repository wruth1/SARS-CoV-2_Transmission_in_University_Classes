
using DataFrames
using CSV
using ProgressMeter
using JLD2          # Save and load variables
using LightGraphs   # For graph functions
using GraphDataFrameBridge  # For extracting the graph from our dataset
using GraphPlot



data = DataFrame(CSV.File("Data/Small-Data.csv"))

student_ids = unique(data[:, :anonymized_emplid])
course_ids = unique(data[:, :Anonymized_Crs_ID])

num_students = length(student_ids)
num_courses = length(course_ids)

q = MetaGraph(data, :anonymized_emplid, :Anonymized_Crs_ID)
nv(q)

# ---------------------------------------------------------------------------- #
#              Relabel student and course ids to distinguish type              #
# ---------------------------------------------------------------------------- #

# --------- Create maps from old to new ids for students and courses --------- #
student_map = Dict()
for i in eachindex(student_ids)
    student_map[student_ids[i]] = "S$i"
end

course_map = Dict()
for i in eachindex(course_ids)
    course_map[course_ids[i]] = "C$i"
end

# ------------------------- Apply maps to get new ids ------------------------ #
student_labels = [student_map[data[i, :anonymized_emplid]] for i in 1:nrow(data)]
course_labels = [course_map[data[i, :Anonymized_Crs_ID]] for i in 1:nrow(data)]

# -------------------------- Add new ids to dataset -------------------------- #
data[:, :student] = student_labels
data[:, :course] = course_labels




# ---------------------------------------------------------------------------- #
#                                Construct graph                               #
# ---------------------------------------------------------------------------- #

q = MetaGraph(data, :student, :course)



# ---------------------------------------------------------------------------- #
#                           Create enrollment matrix                           #
# ---------------------------------------------------------------------------- #

"""
If not already accounted for, enroll student i in class j.
"""
function enroll!(enrollment, i, j)
    this_pos = enrollment[i,j]
    this_pos == 0 ? enrollment[i,j] = 1 : nothing
end

"""
Extracts digits from the string str, and converts to Int64
"""
function get_number(str)
    num_str = match(r"\d+", str).match
    num = parse(Int64, num_str)
end

# -------------------------- Build enrollment matrix ------------------------- #
enrollment = Matrix{Int64}(undef, num_students, num_courses)
for i in 1:nrow(data)
    student_ind = get_number(data[i, :student])
    course_ind = get_number(data[i, :course])

    enroll!(enrollment, student_ind, course_ind)
end


# ---------------------------------------------------------------------------- #
#                  Compute student-by-student adjacency_matrix                 #
# ---------------------------------------------------------------------------- #

# ToDo Multiply enrollment by itself, then map all positive entries to 1
# ToDo After this, construct the student-by-student graph and find the largest connected component
# ToDo It would also be worthwhile to re-read our paper to make sure I haven't missed anything else major