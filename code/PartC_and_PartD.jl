include("RunSimulation.jl")
using Plots
using LaTeXStrings

# Part C
#= "Now, turn on drag (γ=.0005). Make a graph of impact point as a function of dt. Find optimal dt (smallest dt at which we reaconvergence) =#
# Part D
#= Now find optimal dt for γ=.05 and γ=.01, and find if the optimal dt depends on the value of γ=#

# --- setup parameters ---
dt_values = 2.0 .^ (0:-1:-16) .* 1.00   # from 1s to ~0.00006s
γ = 0.05                                # drag coefficient (for C and D, b = 0.0005, .05, .01)
θ₀ = 60.0                               # launch angle (degrees)

# --- run simulations and collect impact points ---
impact_points = Float64[]
for dt in dt_values
    impact_x = run_simulation_with_impact(dt, γ, θ₀)
    push!(impact_points, impact_x)
    println("dt = $dt, impact point = $(round(impact_x, digits=2)) m")
end

# --- find optimal dt based on convergence ---
# use absolute differences as "errors" for convergence analysis
impact_errors = abs.(diff(impact_points))

impact_errors_padded = [1e-10; impact_errors] # avoid zero error for the first element

# find optimal dt using the extracted convergence function
optimal_dt, optimal_error = find_optimal_dt(impact_errors_padded, dt_values)
optimal_idx = findfirst(==(optimal_dt), dt_values)
optimal_impact = impact_points[optimal_idx]

println("\nOptimal dt: $optimal_dt s")
println("Impact point at optimal dt: $(round(optimal_impact, digits=2)) m")

# --- plotting ---
p1 = plot(dt_values, impact_points,
     xlabel="Time Step dt (s)",
     ylabel="Impact Point (m)",
     title="Impact Point vs Time Step",
     marker=:circle,
     markersize=4,
     linewidth=2,
     label="",
     legend=:topleft,
     grid=true,
     xscale=:log10)

# add horizontal line at optimal impact point
hline!([optimal_impact], label="Optimal dt = $(round(optimal_dt,sigdigits=3)) s", linestyle=:dash, color=:red)

p2 = plot(dt_values[1:end-1], impact_errors,
     xlabel="Time Step dt (s)",
     ylabel="Impact Point Error (m) (log scale)",
     title="Impact Point Error vs Time Step",
     marker=:circle,
     markersize=4,
     linewidth=2,
     label="",
     legend=:topleft,
     grid=true,
     xscale=:log10,
     yscale=:log10)
# add horizontal line at optimal errors
hline!([optimal_error], label="Optimal Error = $(round(optimal_error,sigdigits=3)) m", linestyle=:dash, color=:blue)

plot(p1, p2, layout=(1,2), size=(1200,600))
filename = "PartC_$(round(γ,sigdigits=3)).png"
savefig(filename)
println("Plot saved as $filename")
