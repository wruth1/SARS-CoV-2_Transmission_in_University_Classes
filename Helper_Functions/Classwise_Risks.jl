# Compute the probability of transmission along a single pair with the transmitter having the given proportionality constant
function transmit_prob(class_size, infect_param)
    if infect_param > 1
        @warn "Large infectiousness parameter of $infect_param may lead to problems"
    end
    prob = infect_param / sqrt(class_size)
    if prob > 1
        throw(DomainError("Infectiousness parameter is too large: transmission probability greater than 1"))
    end
    prob
end

# Compute risk of a single class
function class_risk(class, infect_param_A, infect_param_I)
    size = class["size"]
    p_A = transmit_prob(size, infect_param_A)
    p_I = transmit_prob(size, infect_param_I)

    n_A = length(class["A"])
    n_I = length(class["I"])

    # Probability of no infection from the specified compartment
    contrib_A = (1 - p_A)^n_A
    contrib_I = (1 - p_I)^n_I

    risk = 1 - contrib_A * contrib_I
end


### Incorporate the computed risk into the class
### Note: can also be used to update the class risk if number of As or Is has changed
function compute_risk!(class, infect_param_A, infect_param_I)
    class["risk"] = class_risk(class, infect_param_A, infect_param_I)
end