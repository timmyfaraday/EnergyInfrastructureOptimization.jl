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
import Interpolations
import JuMP
import Measurements

# using pkgs
using Clp
using Unitful
using UnitfulRecipes


# pkg constants
const _INT = Interpolations
const _MSM = Measurements

# paths
const BASE_DIR = dirname(@__DIR__)

# include
include("core/types.jl")

include("io/financial.jl")
include("io/technology.jl")

include("prob/screening_curve.jl")

# export
export BASE_DIR

export CandidateTechnology, ExistingTechnology

export annuity_factor, screening_curve

end
