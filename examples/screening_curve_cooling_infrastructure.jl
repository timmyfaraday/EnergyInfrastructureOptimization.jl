### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 0d0274f0-6561-11eb-1cc6-651967cb6a49
begin
	# import the package manager
	import Pkg
	Pkg.activate(mktempdir())
	# add the necessary packages
	Pkg.add("AdditionalUnits")
	Pkg.add("CSV")
	Pkg.add("DataFrames")
	Pkg.add("Measurements")
	Pkg.add("Plots")
	Pkg.add("Unitful")
	Pkg.add("UnitfulRecipes")
	# build gr for all the beautiful plots
	ENV["GRDIR"] = ""
	Pkg.build("GR")
	# add the BASF Infrastructure Planning pkg
	url = "https://github.com/timmyfaraday/EnergyInfrastructureOptimization.jl.git"
	Pkg.add(url = url)
	# load all necessary packages
	using AdditionalUnits, CSV, DataFrames, EnergyInfrastructureOptimization
	using Measurements, Plots, Unitful, UnitfulRecipes
	# define a const for the BASF Infrastructure Planning pkg
	const _EIO = EnergyInfrastructureOptimization
end;

# ╔═╡ 877fb5ee-5fe7-11eb-083e-e3cae9963594
md"
### Load the necessary packages

All necessary packages are loaded by in the cell below, if this pluto script is excecuted via binder, this will take approximately **400 seconds**. Feel free to read through the script and become familiar with its features. Once all bars on the left hand of each cell have turned solid gray, all the code is loaded and the user can start altering the script.
"

# ╔═╡ a568b610-5fe3-11eb-07bf-6dfbf5348457
md"
# Screening Curve Method for Cooling Infrastructure at BASF Antwerp

This script enables the evaluation of different cooling technologies using the screening curve method. The screening curve method is an intuitive and fast model that estimates the least cost cooling technology mix based on their annual fixed and variable costs. 

For a detailed discussion on the topic, the reader is referred to the master thesis: *Screening curve method for cooling power - a BASF Antwerp application* by Jan Gagelmans.
"

# ╔═╡ 2deaf150-5fea-11eb-3a98-33ddedb73941
md"
## Load duration curve

The available load duration curves are the ones from the master thesis of Jan Gagelmans, the user can choose between years 2013, 2014, 2015 and 2016 by entering the year in the cell below, e.g., year = 2015."


# ╔═╡ 648b8d10-6548-11eb-1cbd-9317d7b39a98
year = 2013;

# ╔═╡ 430e78e0-5fea-11eb-0c95-7b184b7962f0
begin
	path = joinpath(_EIO.BASE_DIR,"examples/data/ldc.csv")
	ldc  = CSV.read(path, DataFrame)[!,string(year)]u"MW"
	t = range(0.0u"hr/yr",8760.0u"hr/yr",length=length(ldc))
	plot(t, ldc, 
	 		xlabel="time", ylabel="power demand", 
	 		ylim=(0.0u"MW",maximum(ldc)),
	 		legend=false)
end

# ╔═╡ ed3d3a00-5fee-11eb-32d7-91ecff6be0eb
md"
## General constants
In the following cell some general constants are defined. The user can freely add constants, following the these rules:
- the variable name, e.g., r for interest rate, must be unique throughout the script;
- if a variable has a unit, e.g., MW, it is added after the value as u\"MW\" ; and
- if a variable has an uncertainty range, e.g., the electricity price can be 5€/MWh more or less than expected, is obtained by changing p = 51.38u\"€/MWh\" into p = (51.38 ± 5.0)u\"€/MWh\". The operator ± can be obtained by \pm followed by tab.
"

# ╔═╡ b11439be-5fee-11eb-0fb4-bd6d7ede7ef7
begin
	r  = 0.075 										# interest rate
	p  = (51.38±5.0)u"€/MWh"						# electricity price
	ρ  = 997u"kg/m^3"								# density of water
	cp = 4.186u"kJ/kg/K"							# specific heat of water
end;

# ╔═╡ fd0b1c60-5fe7-11eb-0f0a-775a5ac2cddc
md"
## Defining the different technologies

Two classes of technologies exist: ExistingTechnology and CandidateTechnology. An ExistingTechnology is a technology which is already in the system, and is defined by its unique name [String], its capacity [Number] and its variable cost [Number]. For example:

```
eLTC = ExistingTechnology(name = \"eLTC\", vc = 100.0u\"€/MWh\", cap = 100u\"MW\")
```

An CandidateTechnology is a technology which is not yet in the system, and is defined by its unique name [String], its fixed cost [Number] and its variable cost [Number]. For example:

```
LTC = ExistingTechnology(name = \"LTC\", vc = 100.0u\"€/MWh\", fc = 1000.0u\"€/MW/yr\")
```

Before the definition of each technology an additional cell is included to allow for some preemptive calculation of the necessary attributes. A cell is simply added following another by clicking the plus button on the bottom left of the previous cell.

Any cell's console output is surpressed by ending it with ;
"

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
end;

# ╔═╡ 285a1080-5fe6-11eb-3927-dde8671180b2
LCT = CandidateTechnology(name = "LCT", fc = fcˡ, vc = vcˡ);

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
end;

# ╔═╡ 7adb6440-5fe5-11eb-23d0-1759c5ba2f45
SCT = CandidateTechnology(name = "SCT", fc = fcˢ, vc = vcˢ);

# ╔═╡ 637553d0-5ff2-11eb-0503-df2ff89fbd6c
md"
### Brack Water System 
"

# ╔═╡ e4a62470-5ff2-11eb-025e-058911613483
md"
**PUMPING STATION**
"

# ╔═╡ b4ea2420-5ff2-11eb-286b-01a08be859f7
begin
	Eᵖ  = 0.1u"kWh/m^3" 							# electricity consumption
	fᵖ  = 0.01009u"€/m^3"							# water consumption tax
	Iᵖ  = 18.0u"M€"									# investment cost
	Vᵖ  = 84000.0u"m^3/hr"							# flow rate
	Φᵖ  = 16.0u"yr"									# lifetime
	ΔTᵖ = 7.31u"K"									# temperature difference
	
	Qᵖ  = cp * ρ * Vᵖ * ΔTᵖ 						# cooling capacity
	
	fcᵖ  = Iᵖ / Qᵖ / annuity_factor(Φ = Φᵖ, r = r) |> u"€/MW/yr"
	vcᵇ = (fᵖ + p * Eᵖ) * Vᵖ / Qᵖ |> u"€/MWh"
end;

# ╔═╡ 4eebd770-5ff4-11eb-3683-b39940bc1c69
md"
**PIPING NETWORK**
"

# ╔═╡ 5bae4a60-5ff4-11eb-39c4-4fd884b569c8
begin
	dⁿ  = 2.0u"m"									# diameter of a pipe
	cⁿ  = 10000.0u"€/m"								# cost of piping per meter
	lⁿ  = 2500.0u"m"								# length of piping on-site
	vⁿ  = 2.0u"m/s"									# flow velocity
	Φⁿ  = 50.0u"yr"									# lifetime
	ΔTⁿ = 7.31u"K"									# temperature difference
	
	Vⁿ  = 3600.0u"s/hr" * (dⁿ / 2)^2 * π * vⁿ 		# flow rate
	Qⁿ  = cp * ρ * Vⁿ * ΔTⁿ 						# cooling capacity 
	
	fcᵇ = fcᵖ + lⁿ * cⁿ / Qⁿ / annuity_factor(Φ = Φⁿ, r = r) |> u"€/MW/yr"
end;

# ╔═╡ c9138840-6558-11eb-10bf-e5a532ee083e
BWS = CandidateTechnology(name = "BWS", fc = fcᵇ, vc = vcᵇ);

# ╔═╡ bc2d38a0-6563-11eb-0879-2bbe9de01667
md"
### Collect all relevant technologies in an array
"

# ╔═╡ 67216bc0-63eb-11eb-1119-21c28968c608
tech = [LCT, SCT, BWS];

# ╔═╡ 6029b3a0-5fe4-11eb-391f-c32e8d95a813
md"
## Perform the screening curve analysis
"

# ╔═╡ 15cd3c90-5fea-11eb-231d-814a679dfe26
τ, κ = screening_curve(ldc = ldc, tech = tech);

# ╔═╡ 72fe39a0-63eb-11eb-1cc9-77f392b90442
md"
## Plot of the screening curve
"

# ╔═╡ 83f77870-63eb-11eb-2253-0da01bf3ec0c
begin
	# reduced time
	s = t[1:140:end]
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
             xlabel="", ylabel="capacity",
             label="",
             subplot=1)
	scatter!(τ,zero(τ)u"€/MW/yr",
             xlabel="time", ylabel="cost",
             label="",
             subplot=2)
	# plots cosmetics
	plot!(legend=false,
       	  subplot=1)
	plot!(legend=:topleft,
          subplot=2)
end

# ╔═╡ 3febf530-6566-11eb-2d17-1d076ea7542f
md"
**RAPPORT**
"

# ╔═╡ 6122ce7e-6567-11eb-1448-5bc13a06a68f
map(1:length(tech)) do n_n
	n_name = tech[n_n].name
	n_cap  = round(u"MW",κ[n_n])
	n_n == 1 ? n_time = t[end] : n_time = round(u"hr/yr",τ[n_n-1]) ;
	md"$(n_name) works for $(n_time) with a capacity of $(n_cap)"
end

# ╔═╡ Cell order:
# ╟─877fb5ee-5fe7-11eb-083e-e3cae9963594
# ╟─0d0274f0-6561-11eb-1cc6-651967cb6a49
# ╟─a568b610-5fe3-11eb-07bf-6dfbf5348457
# ╟─2deaf150-5fea-11eb-3a98-33ddedb73941
# ╠═648b8d10-6548-11eb-1cbd-9317d7b39a98
# ╟─430e78e0-5fea-11eb-0c95-7b184b7962f0
# ╟─ed3d3a00-5fee-11eb-32d7-91ecff6be0eb
# ╠═b11439be-5fee-11eb-0fb4-bd6d7ede7ef7
# ╟─fd0b1c60-5fe7-11eb-0f0a-775a5ac2cddc
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
# ╠═c9138840-6558-11eb-10bf-e5a532ee083e
# ╟─bc2d38a0-6563-11eb-0879-2bbe9de01667
# ╠═67216bc0-63eb-11eb-1119-21c28968c608
# ╟─6029b3a0-5fe4-11eb-391f-c32e8d95a813
# ╠═15cd3c90-5fea-11eb-231d-814a679dfe26
# ╟─72fe39a0-63eb-11eb-1cc9-77f392b90442
# ╟─83f77870-63eb-11eb-2253-0da01bf3ec0c
# ╟─3febf530-6566-11eb-2d17-1d076ea7542f
# ╟─6122ce7e-6567-11eb-1448-5bc13a06a68f
