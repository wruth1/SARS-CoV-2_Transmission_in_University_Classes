
using Random

"""
    thin_data(address, target_size)

Read-in data from the specified file, remove rows until only target_size remain, then construct the corresponding status object
I.e. Build students and classes, then put them in a container called status

# Arguments
- `address`: The location on disk of the dataset to be read.
- `target_size`: Number of rows to retain in the dataset.
- `seed`: A random seed. 
"""
function thin_data(address, target_size, seed=52501335)

    # ------------------------------- Read-in data ------------------------------- #
    data_big = DataFrame(CSV.File(address))


    # ----------------------- Identify enrollments to keep ----------------------- #
    current_size = nrow(data_big)

    Random.seed!(seed)

    to_keep = sample(1:current_size, target_size, replace=false)


    # ------------------------- Remove excess enrollments ------------------------ #
    data = data_big[to_keep, :]


    ### Get unique student and course IDs
    stu_ids_full = data[!, :anonymized_emplid]
    stu_ids = unique(stu_ids_full)

    crs_ids_full = data[!, :Anonymized_Crs_ID]
    crs_ids = unique(crs_ids_full)


    # ### Trying to build students in parallel
    # students = Vector{Any}(undef, length(stu_ids))
    # @showprogress "Building students..." @distributed for i in eachindex(stu_ids)
    #     students[i] = make_student(data, stu_ids[i], crs_ids)
    # end


    ### Build students
    students = @showprogress "Building students..." [make_student(data, stu_ids[i], crs_ids) for i in eachindex(stu_ids)]


    ### Build classes
    classes = @showprogress "Initializing classes..." [make_empty_class(data, crs_ids[j]) for j in eachindex(crs_ids)]
    incorporate_all_students!(classes, students)
 
    status = Dict("students" => students, "classes" => classes)
    return status
end



