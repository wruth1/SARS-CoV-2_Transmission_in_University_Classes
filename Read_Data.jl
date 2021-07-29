###! WARNING: Building classes requires us to compute classwise risks. However, this calculation depends on the infectiousness parameters.
###!          These parameters must be defined either here or in the calling environment.
# infect_param_A = 1
# infect_param_I = 1

using DataFrames, CSV

"""
    read_data(address, add_risk = true)

Read-in data from the specified file and construct the corresponding status object
I.e. Build students and classes, then put them in a container called status

# Arguments
- `address`: The location on disk of the dataset to be read
- `add_risk`: Whether or not classwise risks should be computed. If true, then infectiousness parameters must be defined in the calling scope.
"""
function read_data(address, add_risk=true)

    data = DataFrame(CSV.File(address))

### Get unique student and course IDs
    stu_ids_full = data[!, :anonymized_emplid]
    stu_ids = unique(stu_ids_full)

    crs_ids_full = data[!, :Anonymized_Crs_ID]
    crs_ids = unique(crs_ids_full)


### Build students
    students = @showprogress "Building students..." [make_student(data, stu_ids[i], crs_ids) for i in eachindex(stu_ids)]


### Build classes
### todo Adding classes to students is very fast. No progress indicator is needed here
    classes = @showprogress "Initializing classes..." [make_empty_class(data, crs_ids[j]) for j in eachindex(crs_ids)]
    @showprogress "Adding students to classes..." for i in eachindex(students)
        this_student = students[i]
        incorporate_student!(classes, this_student, i)
    end
    # incorporate_all_students!(classes, students)
    if add_risk
        @showprogress "Computing classwise risks..." for j in eachindex(classes)
            compute_risk!(classes[j], infect_param_A, infect_param_I)
        end
    end

    status = Dict("students" => students, "classes" => classes)
end