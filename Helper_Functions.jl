# ---------------------------------------------------------------------------- #
#               Calls other scripts which define helper functions              #
# ---------------------------------------------------------------------------- #


using Pipe

files = ("Build_Objects", "Classwise_Risks", "Delete_Objects", "Edit_Compartments", "General_Utilities", "Process_Results",
        "Update_Functions", "Read_Data", "Get_Largest_Component")

@pipe files |>
    "Helper_Functions/" .* _ .* ".jl" |>
    include.(_)