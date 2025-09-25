include("RunSimulation.jl")
using Plots
using LaTeXStrings
using Printf

# Part E: Find thrust force F and time T that compensates for drag
# to achieve the same impact point as the no-drag analytical solution

# --- setup parameters ---
dt = 0.01        # seems to work well enough for this problem
γ = 0.0005        # drag coefficient (b = 0.0005)
θ₀ = 60.0         # launch angle (degrees)

# --- calculate target impact point (no drag analytical solution) ---
s_target = State(θ₀, 0.0, dt)
t_analytical, r_analytical, v_analytical = analytical(s_target)
target_impact = get_impact_point(r_analytical)
println("Target impact point (no drag): $target_impact m")

# --- calculate baseline impact with drag (no thrust) ---
baseline_impact = run_simulation_with_impact(dt, γ, θ₀)
println("Baseline impact with drag (no thrust): $baseline_impact m")
impact_diff_due_to_drag = target_impact - baseline_impact
println("Impact deficit due to drag: $impact_diff_due_to_drag m")

# --- grid search over thrust force and time combinations ---
# define search ranges
thrust_forces = 0:.1:20
thrust_times = 0:.1:25

# initialize tracking variables
best_results = Dict{Float64, Dict{String, Float64}}()

results = zeros(length(thrust_forces), length(thrust_times))

println("Running $(length(thrust_forces)) × $(length(thrust_times)) = $(length(thrust_forces) * length(thrust_times)) simulations...")

for (i, F) in enumerate(thrust_forces)
    for (j, T) in enumerate(thrust_times)
        try
            impact_x = run_simulation_with_thrust(dt, γ, θ₀, F, T)
            error = abs(impact_x - target_impact)
            results[i, j] = error
            percent_error = error / target_impact * 100

            if percent_error < 0.10 # within 0.1% of target
                best_results[error] = Dict(
                    "value" => error,
                    "F" => F,
                    "T" => T,
                    "impact" => impact_x
                )
            end
        # impact_x returns NaN if the projectile never lands
        catch 
            results[i, j] = NaN
        end
    end
    @printf("Completed %3d of %3d force steps (F=%.2f N)\n", i, length(thrust_forces), F)
end

# --- report best results dict ---
for (err_val, stats) in best_results
    println("Error: $err_val m, F: $(stats["F"]) N, T: $(stats["T"]) s, Impact: $(stats["impact"]) m")
end

# --- visualization ---
# plot heatmap of _all_ results
heatmap(thrust_times, thrust_forces, results,
            xlabel="Thrust Time T (s)",
            ylabel="Thrust Force F (N)",
            title="Error Heatmap",
            color=:viridis,
            color_scale=:log10)
best_error_result = Inf
best_F = 0.0
best_T = 0.0
best_impact = 0.0

for stats in values(best_results)
    if stats["value"] < best_error_result
        global best_F = stats["F"]
        global best_T = stats["T"]
        global best_impact = stats["impact"]
        global best_error_result = stats["value"]
    end
end
# place a star at the best T,F combo
scatter!([best_T], [best_F],
         marker=:star, 
         markersize=10, 
         color=:blue,
         label="Best: F=$(round(best_F,digits=1))N, T=$(round(best_T,digits=1))s\nError=$(round(best_error_result,digits=2))m ($(round(best_error_result/target_impact*100,digits=6))%)")

savefig("PartE_thrust_heatmap.png")
