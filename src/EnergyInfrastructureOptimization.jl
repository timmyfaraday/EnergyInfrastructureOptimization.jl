################################################################################
#  Copyright 2021, Tom Van Acker                                               #
################################################################################
# EnergyInfrastructureOptimization.jl                                          #
# A Julia package for energy infrastructure optimization within a large        #
# industrial site.                                                             #
# See http://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl       #
################################################################################

module EnergyInfrastructureOptimization

# import pkgs
import Distributions
import Measurements

# using pkgs
using  Unitful
import Unitful: 𝐍

# pkg constants
const _UF  = Unitful

# paths
const BASE_DIR = dirname(@__DIR__)

# additional units
@refunit    €           "€"         Euro        𝐍               true
@unit       yr          "yr"        Year        31556926u"s"    false
@unit       Wh          "Wh"        WattHour    3600u"J"        true

# init function
function __init__() 
    Unitful.register(EnergyInfrastructureOptimization)
end

# include
include("core/types.jl")

include("io/financial.jl")
include("io/physics.jl")
include("io/technology.jl")

# export
export €, yr, Wh

export Technology

export screeningcurve

end
