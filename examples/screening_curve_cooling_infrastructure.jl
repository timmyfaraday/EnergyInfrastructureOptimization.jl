### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 9e43a710-5fe7-11eb-10aa-f5243292af9a
using EnergyInfrastructureOptimization, Plots, Measurements, Unitful, UnitfulRecipes

# ╔═╡ a568b610-5fe3-11eb-07bf-6dfbf5348457
md"
# Screening Curve Method for Cooling Infrastructure at BASF Antwerp

This script enables the evaluation of different cooling technologies using the screening curve method. The screening curve method is an intuitive and fast model that estimates the least cost cooling technology mix based on their annual fixed and variable costs. 

For a detailed discussion on the topic, the reader is referred to the master thesis: *Screening curve method for cooling power - a BASF Antwerp application* by Jan Gagelmans.
"

# ╔═╡ 877fb5ee-5fe7-11eb-083e-e3cae9963594
md"
### Load the necessary packages
"

# ╔═╡ 2deaf150-5fea-11eb-3a98-33ddedb73941
md"
## Load duration curve
"

# ╔═╡ 430e78e0-5fea-11eb-0c95-7b184b7962f0
ldc = 

# ╔═╡ 0cdd11e0-5feb-11eb-14db-698c8ed68770
s, t = (0.0:120.0:8760.0)u"hr/yr", (0.0:1.0:8760)u"hr/yr"

# ╔═╡ b600bde0-5fea-11eb-2d4c-9d3c873b7012
plot(t, LDC)

# ╔═╡ fd0b1c60-5fe7-11eb-0f0a-775a5ac2cddc
md"
## Defining the different technologies
"

# ╔═╡ ed3d3a00-5fee-11eb-32d7-91ecff6be0eb
md"
**GENERAL CONSTANTS**
"

# ╔═╡ b11439be-5fee-11eb-0fb4-bd6d7ede7ef7
begin
	r  = 0.075 										# interest rate
	p  = 51.38u"€/MWh"								# electricity price
	ρ  = 997u"kg/m^3"								# density of water
	cp = 4.186u"kJ/kg/K"							# specific heat of water
end

# ╔═╡ 3fe978e0-5fef-11eb-257d-298d726aa4a7
md"
### Large Cooling Tower
"

# ╔═╡ 1045f480-5fed-11eb-3e0c-e77e1bb28a0a
begin
	Eˡ  = 0.2u"kWh/m^3"								# electricity consumption
	Iˡ  = 17.98u"M€"								# investment cost
	Vˡ  = 20250u"m^3/hr"							# flow rate
	Qˡ  = 140.65u"MW"								# cooling capacity
	Φˡ  = 16.0u"yr"									# lifetime
	ΔTˡ = 6.0u"K"									# temperature difference
	
	fcˡ = Iˡ / Qˡ / annuity_factor(Φ = Φˡ, r = r) |> u"€/MW/yr"
	vcˡ = p * Eˡ * Vˡ / Qˡ |> u"€/MWh"
end

# ╔═╡ 285a1080-5fe6-11eb-3927-dde8671180b2
LCT = CandidateTechnology(name = "LCT", fc = fcˡ, vc = vcˡ)

# ╔═╡ b79754b0-5ff0-11eb-2dbd-5d0ff8216bc1
md"
### Small Cooling Tower
"

# ╔═╡ d5a2fb30-5ff0-11eb-20cd-5df438adbef0
begin
	Eˢ  = 0.4u"kWh/m^3"								# electricity consumption
	Iˢ  = 1.08u"M€" 								# investment cost
	Qˢ  = 10.06u"MW"								# cooling capacity
	Φˢ  = 16.0u"yr" 								# lifetime
	ΔTˢ = 6.0u"K" 									# temperature difference
	
	fcˢ = Iˢ / Qˢ / annuity_factor(Φ = Φˢ, r = r) |> u"€/MW/yr"
	vcˢ = p * Eˢ / cp / ρ / ΔTˢ |> u"€/MWh"
end

# ╔═╡ 7adb6440-5fe5-11eb-23d0-1759c5ba2f45
SCT = CandidateTechnology(name = "SCT", fc = fcˢ, vc = vcˢ)

# ╔═╡ 637553d0-5ff2-11eb-0503-df2ff89fbd6c
md"
### Brack Water System 
"

# ╔═╡ e4a62470-5ff2-11eb-025e-058911613483
md"
**PUMPING STATION**
"

# ╔═╡ 4eebd770-5ff4-11eb-3683-b39940bc1c69
md"
**PIPING NETWORK**
"

# ╔═╡ 31605b40-5fe5-11eb-3e13-cf152fcd0a03
BWS = ExistingTechnology(name = "BWS", cap = 100.0u"MW", vc = vcᵇ)

# ╔═╡ 6029b3a0-5fe4-11eb-391f-c32e8d95a813
md"
## Perform the screening curve analysis
"

# ╔═╡ 67216bc0-63eb-11eb-1119-21c28968c608
tech = [LCT, SCT, BWS]

# ╔═╡ 15cd3c90-5fea-11eb-231d-814a679dfe26
τ, κ = screening_curve(ldc = ldc, tech = tech)

# ╔═╡ 72fe39a0-63eb-11eb-1cc9-77f392b90442
md"
## Plot of the screening curve
"

# ╔═╡ 83f77870-63eb-11eb-2253-0da01bf3ec0c
begin
	# plots - layout
	plot(layout=(2,1))
	# plots - data
	plot!(t,ldc,
          subplot=1)
	for n_t in tech
    	plot!(s,n_t.ac.(s),
              label=n_t.name,
              subplot=2)
	end 
	scatter!(τ,zero(τ)u"MW",
             xlabel="", ylabel="",
             label="",
             subplot=1)
	scatter!(τ,zero(τ)u"€/MW/yr",
             xlabel="time", ylabel="annual cost",
             label="",
             subplot=2)
	# plots cosmetics
	plot!(legend=false,
       	  subplot=1)
	plot!(legend=:topleft,
          subplot=2)
end

# ╔═╡ b4ea2420-5ff2-11eb-286b-01a08be859f7
begin
	Eᵖ  = 0.1u"kWh/m^3" 							# electricity consumption
	fᵖ  = 0.01009u"€/m^3"							# water consumption tax
	Iᵖ  = 18.0u"M€"									# investment cost
	Vᵖ  = 84000.0u"m^3/hr"							# flow rate
	Φᵖ  = 16.0u"yr"									# lifetime
	ΔTᵖ = 7.31u"K"									# temperature difference
	
	Qᵖ  = cp * ρ * Vᵖ * ΔTᵖ 						# cooling capacity
	
	fcᵇ = Iᵖ / Qᵖ / annuity_factor(Φ = Φᵖ, r = r) |> u"€/MW/yr"
	vcᵇ = (fᵖ + p * Eᵖ) * Vᵖ / Qᵖ |> u"€/MWh"
end

# ╔═╡ 5bae4a60-5ff4-11eb-39c4-4fd884b569c8
begin
	dⁿ  = 2.0u"m"									# diameter of a pipe
	cⁿ  = 10000.0u"€/m"								# cost of piping per meter
	lⁿ  = 2500.0u"m"								# length of piping on-site
	vⁿ  = 2.0u"m/s"									# flow velocity
	Φⁿ  = 50.0u"yr"									# lifetime
	ΔTⁿ = 7.31u"K"									# temperature difference
	
	Vⁿ  = 3600.0 * (dⁿ / 2)^2 * π * vⁿ 				# flow rate
	Qⁿ  = cp * ρ * Vⁿ * ΔTⁿ 						# cooling capacity 
	
	fcᵇ += lⁿ * cⁿ / Qⁿ / annuity_factor(Φ = Φⁿ, r = r) |> u"€/MW/yr"
end

# ╔═╡ Cell order:
# ╟─a568b610-5fe3-11eb-07bf-6dfbf5348457
# ╟─877fb5ee-5fe7-11eb-083e-e3cae9963594
# ╠═9e43a710-5fe7-11eb-10aa-f5243292af9a
# ╟─2deaf150-5fea-11eb-3a98-33ddedb73941
# ╠═430e78e0-5fea-11eb-0c95-7b184b7962f0
# ╠═0cdd11e0-5feb-11eb-14db-698c8ed68770
# ╠═b600bde0-5fea-11eb-2d4c-9d3c873b7012
# ╟─fd0b1c60-5fe7-11eb-0f0a-775a5ac2cddc
# ╟─ed3d3a00-5fee-11eb-32d7-91ecff6be0eb
# ╠═b11439be-5fee-11eb-0fb4-bd6d7ede7ef7
# ╟─3fe978e0-5fef-11eb-257d-298d726aa4a7
# ╠═1045f480-5fed-11eb-3e0c-e77e1bb28a0a
# ╠═285a1080-5fe6-11eb-3927-dde8671180b2
# ╟─b79754b0-5ff0-11eb-2dbd-5d0ff8216bc1
# ╠═d5a2fb30-5ff0-11eb-20cd-5df438adbef0
# ╠═7adb6440-5fe5-11eb-23d0-1759c5ba2f45
# ╟─637553d0-5ff2-11eb-0503-df2ff89fbd6c
# ╟─e4a62470-5ff2-11eb-025e-058911613483
# ╠═b4ea2420-5ff2-11eb-286b-01a08be859f7
# ╟─4eebd770-5ff4-11eb-3683-b39940bc1c69
# ╠═5bae4a60-5ff4-11eb-39c4-4fd884b569c8
# ╠═31605b40-5fe5-11eb-3e13-cf152fcd0a03
# ╟─6029b3a0-5fe4-11eb-391f-c32e8d95a813
# ╠═67216bc0-63eb-11eb-1119-21c28968c608
# ╠═15cd3c90-5fea-11eb-231d-814a679dfe26
# ╟─72fe39a0-63eb-11eb-1cc9-77f392b90442
# ╠═83f77870-63eb-11eb-2253-0da01bf3ec0c
