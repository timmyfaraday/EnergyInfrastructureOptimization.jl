################################################################################
#  Copyright 2021, Tom Van Acker                                               #
################################################################################
# EnergyInfrastructureOptimization.jl                                          #
# A Julia package for energy infrastructure optimization within a large        #
# industrial site.                                                             #
# See http://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl       #
################################################################################

# bounds
lb(x::Number) = _MSM.value(x) - _MSM.uncertainty(x)/2
ub(x::Number) = _MSM.value(x) + _MSM.uncertainty(x)/2

# intersection
intersection(t1::AbstractTechnology, t2::AbstractTechnology) = 
    (t1.fc - t2.fc) / (t2.vc-t1.vc) |> u"hr/yr"

# fixed_cost
fixed_cost(τ::Number, t1::AbstractTechnology, t2::AbstractTechnology) =
    τ * (t2.vc-t1.vc) + t2.fc  |> u"€/MW/yr"

# inferior
inferior(t1::AbstractTechnology, t2::AbstractTechnology) = 
    (t1.fc < t2.fc) && (t1.vc < t2.vc) && t1 isa CandidateTechnology

# effective_capacity_cost
function effective_capacity_cost!(ldc, inv, tech)
    # sets
    T   = (0.0:10.0:8760.0)u"hr/yr"
    C   = [n_t.name for n_t in tech if n_t isa CandidateTechnology]
    E   = [n_t.name for n_t in tech if n_t isa ExistingTechnology]
    U   = [n_t.name for n_t in tech]
    # parameters
    dt  = ustrip.(u"hr/yr",step(T))
    cap = Dict(n_t.name => _UF.ustrip(u"MW", n_t.capacity)
                    for n_t in tech if n_t isa ExistingTechnology)
    fc  = Dict(n_t.name => _MSM.value(_UF.ustrip(u"€/MW/yr", n_t.fc)) 
                    for n_t in tech if n_t isa CandidateTechnology)
    vc  = Dict(n_t.name => _MSM.value(_UF.ustrip(u"€/MWh", n_t.vc))
                    for n_t in tech)
    # optimization model
    m = JuMP.Model(Clp.Optimizer)
    set_optimizer_attribute(m, "LogLevel", 0)
    set_optimizer_attribute(m, "PrimalTolerance", 1e-10)
    set_optimizer_attribute(m, "DualTolerance", 1e-10)
    JuMP.@variable(m, 0.0 <= Q[c in C] <= ustrip.(u"MW",ldc(zero(t[1]))))
    JuMP.@variable(m, 0.0 <= P[u in U, t in T] <= ustrip.(u"MW",ldc(t)))
    JuMP.@constraint(m, [c in C, t in T], P[c,t] <= Q[c])
    JuMP.@constraint(m, [e in E, t in T], P[e,t] <= cap[e])
    JuMP.@constraint(m, [t in T], sum(P[u,t] for u in U) == ustrip.(u"MW",ldc(t)))
    JuMP.@objective(m, Min, sum(dt * vc[u] * P[u,t] for u in U, t in T) +
                        sum(fc[c] * Q[c] for c in C))
    JuMP.optimize!(m)
    # find the expected intersections τ
    mo = ldc(zero(t[1])) .- cumsum(JuMP.value.(P[:,0.0u"hr/yr"]).data)u"MW"
    println(JuMP.value.(P[:,0.0u"hr/yr"]).data)
    τ  = inv.(mo)
    # find the duals of the ExistingTechnologies
    for n_n in 1:length(tech)-1 if tech[n_n] isa ExistingTechnology
        fc = max(tech[n_n].fc, fixed_cost(τ[n_n], tech[n_n], tech[n_n+1]))
        tech[n_n].fc, tech[n_n].ac = fc, annual_cost(fc = fc, vc = tech[n_n].vc)
    end end
end

# screening curve 
"""
    EnergyInfrastructureOptimization.screening_curve

Screening curve
"""
function screening_curve(; ldc::Array, tech::Array)
    # interpolation of the ldc
    t = range(0.0u"hr/yr", 8760.0u"hr/yr", length=length(ldc))
    s = t[1:40:end]
    int = _INT.LinearInterpolation(t, ldc, extrapolation_bc = Line())
    inv = _INT.LinearInterpolation(reverse(ldc), t, extrapolation_bc = Line())
    # sort based on the merit order and eliminate inferior new units
    sort!(tech, by = x -> x.vc)
    deleteat!(tech, [any(x -> inferior(n_t,x), tech) for n_t in tech])
    # determine the expected effective capacity cost for existing units 
    if count(x -> x isa ExistingTechnology, tech) > 0
        effective_capacity_cost!(int, inv, tech)
    end
    # determine all intersections between the curves
    τ = [intersection(tech[n_n], tech[n_n+1]) for n_n in 1:length(tech)-1]
    τ = min.(8766.0u"hr/yr", τ)
    κ = [(int(lb(n_τ))+int(ub(n_τ)))/2 ± (int(lb(n_τ))-int(ub(n_τ))) for n_τ in τ]
    κ = diff([0.0u"MW", κ..., ldc[1]])
    # return results
    return τ, κ
end