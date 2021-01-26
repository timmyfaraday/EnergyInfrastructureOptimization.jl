################################################################################
#  Copyright 2021, Tom Van Acker                                               #
################################################################################
# EnergyInfrastructureOptimization.jl                                          #
# A Julia package for energy infrastructure optimization within a large        #
# industrial site.                                                             #
# See http://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl       #
################################################################################

# annuity factor
"""
    EnergyInfrastructureOptimization.annuity_factor

Annuity factor [yr] 
"""
annuity_factor(; Φ::Number, r::Number) =
    (((1 + r)^ustrip(u"yr", Φ) - 1) / (r * (1 + r)^ustrip(u"yr", Φ)))u"yr"

# variable cost 
"""
    EnergyInfrastructureOptimization.variable_cost

Variable cost [€/MWh]
"""
variable_cost(; E::Number, Q::Number, V::Number, p::Number) =
    p * E * V / Q |> u"€/MWh"

# fixed cost
"""
    EnergyInfrastructureOptimization.fixed_cost

Fixed cost [€/MW/yr]
"""
fixed_cost(; I::Number, Q::Number, A::Number) =  I / Q / A |> u"€/MW/yr"

# annual cost
"""
    EnergyInfrastructureOptimization.annual_cost

Annual cost [u"€/MW/yr"]
"""
annual_cost(; fc::Number, vc::Number) = 
    (t) -> fc + vc * uconvert("hr", t) / 1.0u"yr" |> u"€/MW/yr"