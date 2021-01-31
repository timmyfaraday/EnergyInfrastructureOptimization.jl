################################################################################
#  Copyright 2021, Tom Van Acker                                               #
################################################################################
# EnergyInfrastructureOptimization.jl                                          #
# A Julia package for energy infrastructure optimization within a large        #
# industrial site.                                                             #
# See http://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl       #
################################################################################

# new technology
"""
    EnergyInfrastructureOptimization.CandidateTechnology
"""
struct CandidateTechnology <: AbstractTechnology
    ac::Function
    fc::Number
    name::String
    vc::Number 
end
CandidateTechnology(; name::String, fc::Number, vc::Number) = 
    CandidateTechnology(annual_cost(fc = fc, vc = vc), fc, name, vc)

# existing technology
"""
    EnergyInfrastructureOptimization.ExistingTechnology
"""
mutable struct ExistingTechnology <: AbstractTechnology
    ac::Function
    capacity::Number
    fc::Number
    name::String
    vc::Number
end
ExistingTechnology(; name::String, cap::Number, vc::Number) = 
    ExistingTechnology(annual_cost(fc = 0.0u"€/MW/yr", vc = vc), cap, 0.0u"€/MW/yr", name, vc)