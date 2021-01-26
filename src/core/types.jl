################################################################################
#  Copyright 2021, Tom Van Acker                                               #
################################################################################
# EnergyInfrastructureOptimization.jl                                          #
# A Julia package for energy infrastructure optimization within a large        #
# industrial site.                                                             #
# See http://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl       #
################################################################################

# abstract types
abstract type AbstractTechnology end

# technology 
struct Technology <: AbstractTechnology
    name::String
    fixed_cost::Number
    variable_cost::Number
    annual_cost::Function
end
Technology(; name::String, fc::Number, vc::Number) = 
    Technology(name, fc, vc, annual_cost(fc = fc, vc = vc))