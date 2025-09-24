include("RunSimulation.jl")
using Plots
using LaTeXStrings
using Printf

# Part E: Find thrust force F and time T that compensates for drag
# to achieve the same impact point as the no-drag analytical solution

# --- setup parameters ---
dt = 0.01         # use a reasonable timestep (from previous analysis)
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
thrust_forces = 0:.25:20
thrust_times = 0:.25:25

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

    # Progress indicator
    if i % 5 == 0
        println("  Completed $i/$(length(thrust_forces)) force values...")
    end
end

# --- report best results dict ---
println("\n=== BEST RESULTS ===")
for (err_val, stats) in best_results
    println("Error: $err_val m, F: $(stats["F"]) N, T: $(stats["T"]) s, Impact: $(stats["impact"]) m")
end

# --- visualization ---
println("\nCreating visualizations...")
# plot heatmap of _all_ results
p1 = heatmap(thrust_times, thrust_forces, results,
            xlabel="Thrust Time T (s)",
            ylabel="Thrust Force F (N)",
            title="Error Heatmap",
            # make colorbar log scale
            color=:viridis,
            color_scale=:log10)
# place a star directly onto p1 at the best results
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
scatter!(p1, [best_T], [best_F],
         marker=:star, markersize=10, color=:blue,
         label="Best: F=$(round(best_F,digits=1))N, T=$(round(best_T,digits=1))s\nError=$(round(best_error_result,digits=2))m ($(round(best_error_result/target_impact*100,digits=6))%)")

savefig(p1, "PartE_thrust_heatmap.png")
#=
# 1. Contour plot of error surface
p1 = contour(thrust_times, thrust_forces, results,
            xlabel="Thrust Time T (s)",
            ylabel="Thrust Force F (N)",
            title="Error Surface: |Impact - Target|",
            fill=true,
            levels=20)

# Mark best combination
scatter!([best_T], [best_F],
         marker=:star, markersize=10, color=:red,
         label="Best: F=$(round(best_F,digits=1))N, T=$(round(best_T,digits=1))s")

# 2. Heatmap of results
p2 = heatmap(thrust_times, thrust_forces, results,
            xlabel="Thrust Time T (s)",
            ylabel="Thrust Force F (N)",
            title="Error Heatmap",
            color=:viridis)

scatter!([best_T], [best_F],
         marker=:star, markersize=10, color=:red)

# 3. Show trajectory comparison for best case
println("Computing trajectory comparison...")
s_nodrag = State(θ₀, 0.0, dt)
t_nodrag, r_nodrag, v_nodrag = analytical(s_nodrag)

s_drag = State(θ₀, γ, dt)
t_drag, r_drag, v_drag = numerical(s_drag)

s_thrust = State(θ₀, γ, dt)
t_thrust, r_thrust, v_thrust = numerical_with_thrust(s_thrust, best_F, best_T)

p3 = plot(r_nodrag[1,:], r_nodrag[2,:],
         label="No drag (target)", linewidth=3, color=:green)
plot!(r_drag[1,:], r_drag[2,:],
      label="With drag (no thrust)", linewidth=2, color=:red, linestyle=:dash)
plot!(r_thrust[1,:], r_thrust[2,:],
      label="With drag + thrust", linewidth=2, color=:blue)

xlabel!("Horizontal Distance (m)")
ylabel!("Vertical Distance (m)")
title!("Trajectory Comparison")
hline!([0], color=:black, linestyle=:dot, label="Ground")

# Combine plots
combined_plot = plot(p1, p2, p3,
                    layout=(2,2),
                    size=(1200,800),
                    dpi=600)

savefig(combined_plot, "PartE_thrust_analysis.png")
println("Plot saved as PartE_thrust_analysis.png")

# 4. Create a simple summary table
println("\n=== SUMMARY TABLE ===")
println("| Configuration | Impact Point (m) | Error (m) | Error (%) |")
println("|---------------|-----------------|-----------|-----------|")
@printf("| No drag (target) | %8.2f | %8.2f | %7.2f%% |\n", target_impact, 0.0, 0.0)
@printf("| With drag only   | %8.2f | %8.2f | %7.2f%% |\n", baseline_impact, abs(baseline_impact - target_impact), abs(baseline_impact - target_impact)/target_impact*100)
@printf("| With drag + thrust | %8.2f | %8.2f | %7.2f%% |\n", best_impact, best_error, best_error/target_impact*100)
println("Optimal thrust: F = $(round(best_F, digits=2)) N for T = $(round(best_T, digits=2)) s")
=#
