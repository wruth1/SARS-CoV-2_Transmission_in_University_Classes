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

# Compute risk of a single class (i.e. daily infection probability of a single susceptible)
function class_risk(class, infect_param_A, infect_param_I1, infect_param_I2)
    size = class["size"]
    p_I1 = transmit_prob(size, infect_param_I1)
    p_I2 = transmit_prob(size, infect_param_I2)
    p_A = transmit_prob(size, infect_param_A)

    n_I1 = length(class["I1"])
    n_I2 = length(class["I2"])
    n_A = length(class["A"])

    # Probability of no infection from the specified compartment
    contrib_I1 = (1 - p_I1)^n_I1
    contrib_I2 = (1 - p_I2)^n_I2
    contrib_A = (1 - p_A)^n_A

    risk = 1 - contrib_I1 * contrib_I2 * contrib_A
end


### Incorporate the computed risk into the class
### Note: can also be used to update the class risk if number of As or Is has changed
function compute_risk!(class, infect_param_A, infect_param_I1, infect_param_I2)
    class["risk"] = class_risk(class, infect_param_A, infect_param_I1, infect_param_I2)
end