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
    (t1.fc > t2.fc) && (t1.vc > t2.vc) && t1 isa CandidateTechnology

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
    JuMP.set_optimizer_attribute(m, "LogLevel", 0)
    JuMP.set_optimizer_attribute(m, "PrimalTolerance", 1e-10)
    JuMP.set_optimizer_attribute(m, "DualTolerance", 1e-10)
    JuMP.@variable(m, 0.0 <= Q[c in C] <= ustrip.(u"MW",ldc(T[1])))
    JuMP.@variable(m, 0.0 <= P[u in U, t in T] <= ustrip.(u"MW",ldc(t)))
    JuMP.@constraint(m, [c in C, t in T], P[c,t] <= Q[c])
    JuMP.@constraint(m, [e in E, t in T], P[e,t] <= cap[e])
    JuMP.@constraint(m, [t in T], sum(P[u,t] for u in U) == ustrip.(u"MW",ldc(t)))
    JuMP.@objective(m, Min, sum(dt * vc[u] * P[u,t] for u in U, t in T) +
                        sum(fc[c] * Q[c] for c in C))
    JuMP.optimize!(m)
    # find the expected intersections τ
    mo  = cumsum(JuMP.value.(P[:,0.0u"hr/yr"]).data)u"MW"
    println(mo)
    τ   = inv.(mo)
    println(τ)
    # find the duals of the ExistingTechnologies
    Nt   = length(tech)
    A, b = zeros(Nt,Nt), zeros(Nt)u"€/MW/yr"
    n_n  = 1
    for n_t in 1:length(τ) if τ[n_t] > 0.0u"hr/yr"
        A[n_t,n_t], A[n_t,n_t+1] = 1, -1
        b[n_t] = τ[n_t] * (tech[n_t+1].vc - tech[n_t].vc)
        n_n += 1
    end end
    for n_t in 1:length(tech) if tech[n_t] isa CandidateTechnology
        A[n_n,n_t], b[n_n] = 1, tech[n_t].fc
        n_n += 1
        if n_n > length(tech) break end 
    end end
    Fc = max.(zeros(length(b))u"€/MW/yr", A \ b)
    println(Fc)
    for n_t in 1:length(tech) if tech[n_t] isa ExistingTechnology
        tech[n_t].fc, tech[n_t].ac = Fc[n_t], annual_cost(fc = Fc[n_t], vc = tech[n_t].vc)
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
    int = _INT.LinearInterpolation(t, ldc, extrapolation_bc = _INT.Line())
    inv = _INT.LinearInterpolation(reverse(ldc), reverse(t), extrapolation_bc = _INT.Line())
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