using Test

@testset "Update_Functions" begin
    include("Toy_Simulation.jl")
    include("Update_Functions.jl")

    @testset "Update_S!" begin
        update_S!(status_new, status_old)

        students_old = status_old["students"]
        students_new = status_new["students"]

        S_old = get_compartments(students_old, "S")
        S_new = get_compartments(students_new, "S")

        E_old = get_compartments(students_old, "E")
        E_new = get_compartments(students_new, "E")

        # Check that no new susceptibles have been introduced
        @test length(setdiff(S_new, S_old)) == 0

        # Check that no exposeds have been deleted
        @test length(setdiff(E_old, E_new)) == 0

        # Check that everything removed from S has been added to E
        S_diff = setdiff(S_old, S_new)
        E_diff = setdiff(E_new, E_old)
        @test issetequal(S_diff, E_diff)
    end

    @testset "Update_E!" begin

        @testset "Basic" begin
        advance_prob_E = 0.2 # Probability of an E moving to either A or I on a particular day
            E_to_A_prob = 0.5 # Probability that an advancement from E is to A

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)

            students_old = status_old["students"]
            students_new = status_new["students"]

            E_old = get_compartments(students_old, "E")
            E_new = get_compartments(students_new, "E")

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            # Check that no new exposeds have been introduced
            @test length(setdiff(E_new, E_old)) == 0

            # Check that no asymptomatics have been deleted
            @test length(setdiff(A_old, A_new)) == 0

            # Check that no infecteds have been deleted
            @test length(setdiff(I_old, I_new)) == 0

            # Check that all removed Es have been added to either A or I
            E_diff = setdiff(E_old, E_new)
            A_diff = setdiff(A_new, A_old)
            I_diff = setdiff(I_new, I_old)
            @test issetequal(E_diff, union(A_diff, I_diff))
        end

        @testset "No Outflow" begin
            advance_prob_E = 0 # Probability of an E moving to either A or I on a particular day
            E_to_A_prob = 0.5 # Probability that an advancement from E is to A

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)

            students_old = status_old["students"]
            students_new = status_new["students"]

            E_old = get_compartments(students_old, "E")
            E_new = get_compartments(students_new, "E")

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            # Check that no changes have occurred with any compartment
            @test E_old == E_new
            @test A_old == A_new
            @test I_old == I_new
        end
            
        @testset "Complete Outflow" begin
            advance_prob_E = 1 # Probability of an E moving to either A or I on a particular day
            E_to_A_prob = 0.5 # Probability that an advancement from E is to A

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)

            students_old = status_old["students"]
            students_new = status_new["students"]

                E_old = get_compartments(students_old, "E")
            E_new = get_compartments(students_new, "E")

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            # Check that E is now empty
            @test length(E_new) == 0

            # Check that no asymptomatics or infecteds have been deleted
            @test length(setdiff(A_old, A_new)) == 0
            @test length(setdiff(I_old, I_new)) == 0

            # Check that all former Es have been added to either A or I
            A_diff = setdiff(A_new, A_old)
            I_diff = setdiff(I_new, I_old)
            @test issetequal(E_old, union(A_diff, I_diff))
        end

        @testset "No Asymptomatics" begin
            advance_prob_E = 0.2 # Probability of an E moving to either A or I on a particular day
            E_to_A_prob = 0 # Probability that an advancement from E is to A

        status_new = deepcopy(status_old) # Make a new copy of status_new
            update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)

            students_old = status_old["students"]
            students_new = status_new["students"]

            E_old = get_compartments(students_old, "E")
            E_new = get_compartments(students_new, "E")

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            # Check that no new exposeds have been introduced
            @test length(setdiff(E_new, E_old)) == 0

            # Check that no changes have occurred with A
            @test A_old == A_new

            # Check that no infecteds have been deleted. If this fails then the next test will also fail
            @test length(setdiff(I_old, I_new)) == 0

            # Check that all removed exposeds have been added to I
            E_diff = setdiff(E_old, E_new)
            I_diff = setdiff(I_new, I_old)
            @test issetequal(E_diff, I_diff)
            end

        @testset "No Infecteds" begin
            advance_prob_E = 0.2 # Probability of an E moving to either A or I on a particular day
            E_to_A_prob = 1 # Probability that an advancement from E is to A

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_E!(status_new, status_old, advance_prob_E, E_to_A_prob)

            students_old = status_old["students"]
            students_new = status_new["students"]

            E_old = get_compartments(students_old, "E")
            E_new = get_compartments(students_new, "E")

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            # Check that no new exposeds have been introduced
            @test length(setdiff(E_new, E_old)) == 0

            # Check that no changes have occurred with I
            @test I_old == I_new

            # Check that no asymptomatics have been deleted. If this fails then the next test will also fail
            @test length(setdiff(A_old, A_new)) == 0
            
            # Check that all removed exposeds have been added to A
            E_diff = setdiff(E_old, E_new)
            A_diff = setdiff(A_new, A_old)
            @test issetequal(E_diff, A_diff)
        end
    end

            @testset "Update_A!" begin
        @testset "Basic" begin
            recovery_prob_A = 0.2 # Probability of an A moving to R on a particular day

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_A!(status_new, status_old, recovery_prob_A)

            students_old = status_old["students"]
            students_new = status_new["students"]

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            R_old = get_compartments(students_old, "R")
            R_new = get_compartments(students_new, "R")

            # Check that no new asymptomatics have been introduced
            @test length(setdiff(A_new, A_old)) == 0

            # Check that no recoverds have been deleted
            @test length(setdiff(R_old, R_new)) == 0

            # Check that everything removed from A has been added to R
            A_diff = setdiff(A_old, A_new)
            R_diff = setdiff(R_new, R_old)
            @test issetequal(A_diff, R_diff)
        end

        @testset "No Outflow" begin
            recovery_prob_A = 0 # Probability of an A moving to R on a particular day

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_A!(status_new, status_old, recovery_prob_A)

    students_old = status_old["students"]
            students_new = status_new["students"]

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            R_old = get_compartments(students_old, "R")
            R_new = get_compartments(students_new, "R")

            # Check that no change has occurred in any compartment
            @test issetequal(A_old, A_new)
            @test issetequal(R_old, R_new)
        end

        @testset "Complete Outflow" begin
            recovery_prob_A = 1 # Probability of an A moving to R on a particular day

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_A!(status_new, status_old, recovery_prob_A)

            students_old = status_old["students"]
            students_new = status_new["students"]

            A_old = get_compartments(students_old, "A")
            A_new = get_compartments(students_new, "A")

            R_old = get_compartments(students_old, "R")
            R_new = get_compartments(students_new, "R")

            # Check that A is now empty
            @test length(A_new) == 0

            # Check that no recoverds have been deleted
            @test length(setdiff(R_old, R_new)) == 0

            # Check that all former As have been added to R
            R_diff = setdiff(R_new, R_old)
            @test issetequal(A_old, R_diff)
        end
    end

            @testset "Update_I!" begin
        @testset "Basic" begin
            recovery_prob_I = 0.2 # Probability of an I moving to R on a particular day

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_I!(status_new, status_old, recovery_prob_I)

            students_old = status_old["students"]
            students_new = status_new["students"]

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            R_old = get_compartments(students_old, "R")
            R_new = get_compartments(students_new, "R")

            # Check that no new asymptomatics have been introduced
            @test length(setdiff(I_new, I_old)) == 0

            # Check that no recoverds have been deleted
            @test length(setdiff(R_old, R_new)) == 0

            # Check that everything removed from I has been added to R
            I_diff = setdiff(I_old, I_new)
            R_diff = setdiff(R_new, R_old)
            @test issetequal(I_diff, R_diff)
        end

        @testset "No Outflow" begin
            recovery_prob_I = 0 # Probability of an I moving to R on a particular day

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_I!(status_new, status_old, recovery_prob_I)

            students_old = status_old["students"]
            students_new = status_new["students"]

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            R_old = get_compartments(students_old, "R")
            R_new = get_compartments(students_new, "R")

            # Check that no change has occurred in any compartment
            @test issetequal(I_old, I_new)
            @test issetequal(R_old, R_new)
        end

        @testset "Complete Outflow" begin
            recovery_prob_I = 1 # Probability of an I moving to R on a particular day

            status_new = deepcopy(status_old) # Make a new copy of status_new
            update_I!(status_new, status_old, recovery_prob_I)

            students_old = status_old["students"]
            students_new = status_new["students"]

            I_old = get_compartments(students_old, "I")
            I_new = get_compartments(students_new, "I")

            R_old = get_compartments(students_old, "R")
            R_new = get_compartments(students_new, "R")

            # Check that I is now empty
            @test length(I_new) == 0

            # Check that no recoverds have been deleted
            @test length(setdiff(R_old, R_new)) == 0

            # Check that all former Is have been added to R
            R_diff = setdiff(R_new, R_old)
            @test issetequal(I_old, R_diff)
        end
    end

    @testset "transmit_prob" begin
        # A normal class setup
        size = 25
        infect_param = 0.5
        prob = transmit_prob(size, infect_param)
        @test prob == 0.1

        # Zero infectiousness parameter
        infect_param = 0
        prob = transmit_prob(size, infect_param)
        @test prob == 0

        # One infectiousness parameter
        infect_param = 1
        prob = transmit_prob(size, infect_param)
        @test prob == 0.2

        # Invalid infectiousness parameter
        infect_param = 100
        @test_throws DomainError transmit_prob(size, infect_param)
    end

    @testset "class_risk" begin
        @testset "Basic" begin
            infect_param = 0.5

            ### Construct a sample class with known risk
            # Build compartments
            S = collect(1:5)
            E = collect(6:10)
            A = collect(11:15)
            I = collect(16:20)
            R = collect(21:25)

            a_class = Dict{String,Any}("S" => S, "E" => E, "A" => A, "I" => I, "R" => R)

            # Get class size
            compartment_sizes = length.(values(a_class))
            size = sum(compartment_sizes)
            a_class["size"] = size

            


        end
    end

    @testset "update_risk!" begin
        
        



    end
end