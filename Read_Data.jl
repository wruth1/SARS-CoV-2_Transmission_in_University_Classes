### WARNING: Building classes requires us to compute classwise risks. However, this calculation depends on the infectiousness parameters.
###          These parameters must be defined either here or in the calling environment.
#infect_param_A = 1
#infect_param_I = 1

using DataFrames, CSV

### Read-in data from the specified file and construct the corresponding status object
### I.e. Build students and classes, then put them in a container called status
function read_data(address)

    data = DataFrame(CSV.File(address))

### Get unique student and course IDs
    stu_ids_full = data[!, :anonymized_emplid]
    stu_ids = unique(stu_ids_full)

    crs_ids_full = data[!, :Anonymized_Crs_ID]
    crs_ids = unique(crs_ids_full)



### Build students
    students = make_student.(Ref(data), stu_ids, Ref(crs_ids))


### Build classes
    classes = make_empty_class.(Ref(data), crs_ids)
    incorporate_all_students!(classes, students)
    compute_risk!.(classes, infect_param_A, infect_param_I)

    status = Dict("students" => students, "classes" => classes)
end