################################################################################
#  Copyright 2021, Tom Van Acker                                               #
################################################################################
# EnergyInfrastructureOptimization.jl                                          #
# A Julia package for energy infrastructure optimization within a large        #
# industrial site.                                                             #
# See http://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl       #
################################################################################

# global constants
global ρ  = Dict(:water => 997u"kg/m^3")
global cp = Dict(:water => 4.186u"kJ/kg/K")

# flow rate
"""
    EnergyInfrastructureOptimization.flow_rate
Flow rate V [m^3/s]

In fluid dynamics, the volumetric flow rate, syn. volume flow rate, rate of 
fluid flow or volume velocity, is the volume of fluid which passes per unit 
time.

Functions:
- flow_rate(; v::Number, A::Number), determines the flow rate based on the flow
  velocity v [m/s] and cross-sectional vector area [m^2].
- flow_rate(; fluid::Symbol, Q::Number, ΔT::Number), determines the fluid-
  specific flow rate based on cooling power Q [MW] and temperature difference 
  ΔT [K].
"""
flow_rate(; v::Number, A::Number) = 
    v / A |> u"m^3/s"
flow_rate(; fluid::Symbol, Q::Number, ΔT::Number) = 
    Q / cp[fluid] / ρ[fluid] / ΔT |> u"m^3/s"

# cooling capacity
"""
    EnergyInfrastructureOptimization.cooling_power

Cooling capacity Q [W]

Cooling capacity is the measure of a cooling system's ability to remove heat.

Functions:
- cooling_capacity(; fluid::Symbol, M::Number, ΔT::Number), determines the 
  fluid-specific cooling capacity based on the mass rate M [kg/s] and 
  temperature difference ΔT [K].
- cooling_capacity(; fluid::Symbol, V::Number, ΔT::Number), determines the 
  fluid-specific cooling capacity based on the flow rate V [m^3/s] and 
  temperature difference ΔT [K].
"""
cooling_capacity(; fluid::Symbol, M::Number, ΔT::Number) = 
    cp[fluid] * M * ΔT |> u"W"
cooling_capacity(; fluid::Symbol, V::Number, ΔT::Number) =
    cp[fluid] * ρ[fluid] * V * ΔT |> u"W"

