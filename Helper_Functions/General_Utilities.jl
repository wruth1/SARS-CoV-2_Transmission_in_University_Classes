"""
Create a vector containing all combinations of elements in arguments. Takes any number of arguments.

Note: This is the same as the expand.grid function in R.
"""
function expand_grid(X...)
    vec(collect(Base.product(X...)))
end


"""
Replace all instances of a in X with b
"""
function replace_in_list!(X, a, b)
    X[X.==a] .= b
end


"""
Takes a vector of vectors and returns a non-nested vector containing all elements
"""
function nested2vec(X)
    all_lengths = length.(X)
    total_length = sum(all_lengths)
    Y = Vector(undef, total_length)
    start = 0
    for i in eachindex(all_lengths)
        for j in 1:all_lengths[i]
            Y[start + j] = X[i][j]
        end
        start += all_lengths[i]
    end
    return Y
end    

"""
Converts a vector of equally-sized vectors to a 2D array
"""
function nested2array(X)
    # --------------- Check that all sub-vectors are the same size --------------- #
    all_lengths = length.(X)
    ref = all_lengths[1]
    if !all(all_lengths .== ref); throw("Unequal sized sub-vectors"); end

    # ------------------------- Get type for output array ------------------------ #
    all_types = map(a -> typeof.(a), X)
    array_type = reduce(union, all_types)

    # ----------------------------- Build empty array ---------------------------- #
    N = length(X)
    P = ref
    Y = Array{Any}(undef, (N, P))

    # -------------------------------- Fill array -------------------------------- #
    for i in 1:N
        for j in 1:P
            Y[i,j] = X[i][j]
        end
    end

    return Y
end

"""
Shorthand for number of students in status.
"""
function ns(status)
    length(status["students"])
end


"""
Shorthand for number of classes in status.
"""
function nc(status)
    length(status["classes"])
end

"""
Shorthand for number of students in compartment X
"""
function nsX(status, X)
    students = status["students"]
    this_comp = filter(y -> y["compartment"] == X, students)
    length(this_comp)
end

"""
Extract infection risk for each class
"""
get_risks(status) = [status["classes"][i]["risk"] for i in eachindex(status["classes"])]
