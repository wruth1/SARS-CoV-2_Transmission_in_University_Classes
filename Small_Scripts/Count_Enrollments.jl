
using JLD2              # Save and load variables

function num_classes(student)
    length(student["classes"])
end

# @load "Data/Objects/All_Status_Raws.jld2"    # Status objects without risks

# this_thresh = 20
# status = all_status_raws[this_thresh]
# students = status["students"]
# all_class_nums = num_classes.(students)
# enrollment_count = sum(all_class_nums)
# print(enrollment_count)

# ------ At threshold=20, 32008 enrollments remain in the main component ----- #


enrollment_counts = Dict{Any, Int}()
for (key, status) in all_status_raws
    this_students = status["students"]
    this_count_list = num_classes.(this_students)
    this_count = sum(this_count_list)

    enrollment_counts[key] = this_count
end