### Get all indices in parent_list which correspond to an element of list
function get_indices(list, parent_list)
    findall(x -> in(x, list), parent_list)
end

### Build a student object
### Course ids are required so that we can add the indices of the enrolled classes instead of their ids
function make_student(data, stu_id, crs_ids)
    ### Get ids of classes in which this student is enrolled
    this_entries = filter(row -> row.anonymized_emplid == stu_id, data)
    this_classes = this_entries.Anonymized_Crs_ID

    ### Convert class ids to indices
    this_class_indices = get_indices(this_classes, crs_ids)

    ### Construct the student object with initial compartment "S"
    this_student = Dict("compartment" => "S", "classes" => this_class_indices)
end


### Initialize a class object for the course with the specified id
### I.e. Find days on which it meets, create empty compartments and set size to 0
function make_empty_class(data, crs_id)
    class = Dict()
    
    ### Get the days on which the class meets
    this_entries = filter(row -> row.Anonymized_Crs_ID == crs_id, data)
    an_entry = this_entries[1,:]
    days_vec = Vector(an_entry[[:MON, :TUES, :WED, :THURS, :FRI, :SAT, :SUN]])
    days = findall(x -> x == 1, days_vec)
    class["days"] = days

    ### Create empty compartments
    for X in all_compartments
        class[X] = Vector{Int64}()
    end

    ### Initialize class size
    class["size"] = 0

    class
end
    

### Adds student number ind_student with the specified compartment to class
function add_student!(class, ind_student, compartment)
    class["size"] += 1
    push!(class[compartment], ind_student)
end


### Adds the supplied student object with index i to all of their classes
function incorporate_student!(classes, student, i)
    this_compartment = student["compartment"]
    class_inds = student["classes"]
    this_classes = classes[class_inds]
    add_student!.(this_classes, i, this_compartment)
end

### Adds all students to their classes
function incorporate_all_students!(classes, students)
    for i in eachindex(students)
        this_student = students[i]
        incorporate_student!(classes, this_student, i)
    end
end