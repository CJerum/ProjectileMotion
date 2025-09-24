include("RunSimulation.jl")
using Plots
using LaTeXStrings

# --- run the efficiency analysis ---
dt_values = 2.0 .^ (0:-1:-16) .* 1.00   # from 1s to ~0.00005s 
θ = 60.0                                # initial angle in degrees
optimal_dt = Dict{Int,Float64}()
errors = Float64[]
dts = Float64[]
result = nothing
for dt in dt_values
    global result = Results(dt, 0.0, θ)

    push!(errors, result.error)
    push!(dts, dt)
end

# --- finding optimal dt ---
# calculate ∂(error)/∂(dt) and find the dt where it is minimized

∂err∂t = abs.(diff(errors) ./ diff(dt_values))
min_∂err∂t, min_index = findmin(∂err∂t)
threshold = 1.5 * min_∂err∂t
largest_optimal_timestep = dt_values[findlast(x -> x <= threshold, ∂err∂t)]
largest_optimal_index = findfirst(==(largest_optimal_timestep), dt_values)

println("Completed simulation with dt = $(dts[largest_optimal_index]) s, max error = $(errors[largest_optimal_index]) m")

# --- plotting ---
plot(dt_values, errors,
     xlabel="Time Step dt (s)",
     ylabel="Maximum Error (m)",
     title=L"Error vs Time Step (\theta = %$θ)",
     marker=:circle,
     markersize=6,
     linewidth=2,
     legend=:topleft,
     grid=true,
     xscale=:log10,
     yscale=:log10)
hline!([errors[largest_optimal_index]], linestyle=:dash, color=:red, label="Max Error at dt = $(largest_optimal_timestep) s")

savefig("error_vs_timestep.png")
