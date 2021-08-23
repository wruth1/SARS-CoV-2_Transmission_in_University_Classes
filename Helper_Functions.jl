# ---------------------------------------------------------------------------- #
#               Calls other scripts which define helper functions              #
# ---------------------------------------------------------------------------- #


using Pipe

files = ("Build_Objects", "Classwise_Risks", "Delete_Objects", "Edit_Compartments", "General_Utilities", "Process_Results",
        "Update_Functions.jl", "Read_Data.jl")

@pipe files |>
    "Helper_Functions/" .* _ .* ".jl" |>
    include.(_)