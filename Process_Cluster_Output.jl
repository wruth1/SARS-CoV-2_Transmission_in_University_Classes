
using DataFrames
using JLD2
using Infinity
using ProgressMeter


file_list = readdir("Data/From Cluster/Objects")
file_addresses = "Data/From Cluster/Objects/" .* file_list

function write_batch(a, b, one_file=false)
    data = load(file_addresses[1])
    all_sim_outputs = data["all_sim_outputs"][a:b]
    all_parameters = data["all_parameters"][a:b]

    @showprogress "Building all_sim_outputs" for i in 2:length(file_addresses)
        data = load(file_addresses[i])
        this_sim_outputs = data["all_sim_outputs"][a:b]

        for j in 1:length(a:b)
            container = all_sim_outputs[j]
            to_add = this_sim_outputs[j][1]
            push!(container, to_add)
        end
    end

    if !one_file
        @showprogress "Saving all_sim_outputs" for j in 1:length(a:b)
            j_name = (a-1) + j
            save("Data/Objects/M=10/p=$j_name.jld2", Dict("output" => all_sim_outputs[j], "parameters" => all_parameters[j]))
        end
    else
        @save "Data/Objects/cluster_sim_output.jld2" all_sim_outputs all_parameters
    end
end

A = collect(0:10000:20000)
A = A .+ 1

B = collect(10000:10000:20000)
push!(B, 26244)

n_iter = length(A)

for ii in eachindex(A)
    println("Step $ii of $n_iter")
    a = A[ii]
    b = B[ii]
    write_batch(a,b)
end

# write_batch(1, 26244, false)