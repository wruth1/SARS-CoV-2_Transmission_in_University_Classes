"""
Create a vector containing all combinations of elements in arguments. Takes any number of arguments.

Note: This is the same as the expand.grid function in R.
"""
function expand_grid(X...)
    vec(collect(Base.product(X...)))
end
