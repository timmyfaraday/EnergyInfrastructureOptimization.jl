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

The inverse of the annuity factor, i.e., 1€/AF, gives the yearly cost of 
investing 1€ in year zero. 
"""
annuity_factor(; Φ::Number, r::Number) =
    (((1 + r)^ustrip(u"yr", Φ) - 1) / (r * (1 + r)^ustrip(u"yr", Φ)))u"yr"

# annual cost
"""
    EnergyInfrastructureOptimization.annual_cost

Annual cost [€/MW/yr]

The annual cost is a linear cost function in function of time [hr] based on 
cte fixed costs [€/MW/yr] and variable costs [€/MWh].
"""
annual_cost(; fc::Number, vc::Number) = (t) -> fc + vc * t |> unit(fc)