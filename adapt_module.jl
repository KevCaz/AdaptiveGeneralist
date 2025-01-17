using Parameters
using LinearAlgebra
using ForwardDiff
using PyPlot
using DifferentialEquations
using NLsolve


## Here we will illustrate the case of a generalist predator that ultimately has a climate-driven differential response to its prey. In this case, we change from 
# 20C-30C and show a generalist predator switching between prey in alternate habitats. Here, the generalist predator is omnivorous, and has different temperature responses in different habitats (littoral & pelagic)


## Parameters are categorized by macrohabitat -> parameters with "_litt" indicate littoral macrohabitat values and those with "_pel" indicate pelagic macrohabitat values  

## Parameter alitt in model is the temperature dependent attack rate of P on C_litt and apel is the temperature dependent attack rate of P on C_Pel. All other attack rates are held constant (i.e. not temp dependent)


@with_kw mutable struct AdaptPar
    r_litt = 1.0
    k_litt = 1.0
    α_pel = 0.8      ##competitive influence of pelagic resource on littoral resource 
    r_pel = 1.0
    α_litt = 0.8     ##competitive influence of littoral resource on pelagic resource 
    k_pel = 1.0
    e_CR = 0.8
    h_CR = 0.5
    m_C = 0.2
    a_CR_litt = 1.0
    a_CR_pel = 1.0
    h_PC = 0.5
    h_PR = 0.5
    e_PC = 0.8
    e_PR = 0.8
    m_P = 0.3
    a_PR_litt = 0.2 
    a_PR_pel = 0.2 
    aT_litt = 3.0
    aT_pel = 7.0
    Tmax_litt = 40
    Topt_litt = 32
    Tmax_pel = 32
    Topt_pel = 25
    σ = 6
    T = 0
    
end


## Omnivory Module with Temp Dependent Attack Rates (alitt => aPC in littoral zone; apel => aPC in pelagic zone)

function adapt_model!(du, u, p, t)
    @unpack r_litt, r_pel, k_litt, k_pel, α_pel, α_litt, e_CR, e_PC, e_PR, aT_pel, aT_litt, a_CR_litt, a_CR_pel, a_PR_litt, a_PR_pel, h_CR, h_PC, h_PR, m_C, m_P, T, Topt_litt, Tmax_litt, aT_litt, Topt_pel, Tmax_pel, aT_pel, σ = p 
    
    alitt = ifelse(T < Topt_litt,  
        aT_litt * exp(-((T - Topt_litt)/(2 \σ))^2), 
        aT_litt * (1 - ((T - (Topt_litt))/((Topt_litt) - Tmax_litt))^2)
        )
        
    apel = ifelse(T < Topt_pel, 
        aT_pel * exp(-((T - Topt_pel)/(2 \σ))^2),
        aT_pel * (1 - ((T - (Topt_pel))/((Topt_pel) - Tmax_pel))^2) 
    )
    
    R_litt, R_pel, C_litt, C_pel, P = u
    
    du[1] = r_litt * R_litt * (1 - (α_pel * R_pel + R_litt/ k_litt)) - (a_CR_litt * R_litt * C_litt / (1 + a_CR_litt * h_CR * R_litt)) - (a_PR_litt * R_litt * P/ (1 + a_PR_litt * h_PR * R_litt + a_PR_pel * h_PR * R_pel + alitt * h_PC * C_litt + apel * h_PC * C_pel) )
    du[2] = r_pel * R_pel * (1 - (α_litt * R_pel + R_litt/ k_pel)) - (a_CR_pel * R_pel * C_pel / (1 + a_CR_pel * h_CR * R_pel)) - (a_PR_pel * R_pel * P/ (1 + a_PR_litt * h_PR * R_litt + a_PR_pel * h_PR * R_pel + alitt * h_PC * C_litt + apel * h_PC * C_pel) )
    du[3] = ((e_CR * a_CR_litt * R_litt * C_litt) / (1 + a_CR_litt * R_litt * h_CR)) - (alitt * C_litt * P / ( 1 + a_PR_litt * h_PR * R_litt + a_PR_pel * h_PR * R_pel + alitt * h_PC * C_litt + apel * h_PC * C_pel)) - m_C * C_litt 
    du[4] = ((e_CR * a_CR_pel * R_pel * C_pel) / (1 + a_CR_pel * R_pel * h_CR)) - (apel* C_pel * P / ( 1 + a_PR_litt * h_PR * R_litt + a_PR_pel * h_PR * R_pel + alitt * h_PC * C_litt + apel * h_PC * C_pel)) - m_C * C_pel
    du[5] = (e_PR * a_PR_litt * R_litt * P  + e_PR * a_PR_pel * R_litt * P + e_PC * alitt * C_litt * P + e_PC * apel * C_pel * P) / ( 1 + a_PR_litt * h_PR * R_litt + a_PR_pel * h_PR * R_pel + alitt * h_PC * C_litt + apel * h_PC * C_pel) - m_P * P  
    
    return du
end

let
    u0 = [0.5, 0.4, 0.6, 0.7, 0.1]
    t_span = (0.0, 500.0)

    prob_adapt = ODEProblem(adapt_model!, u0, t_span, p)
    sol = solve(prob_adapt, reltol = 1e-8, abstol = 1e-8)
    
    p = AdaptPar()

    adapt_ts = figure()
    plot(sol.t, sol.u)
    xlabel("time")
    ylabel("Density")
    return adapt_ts

end


















