include("ProjectileMotion.jl")
using .ProjectileMotion
using .ProjectileMotion: m, g
using Plots
using LaTeXStrings
using LinearAlgebra

struct Results
    error::Float64
    comptime::Float64
    error_times_comptime::Float64
    dt::Float64
    impact_point::Float64 # x-coordinate of impact point

    function Results(dt, γ = 0.0, θ₀ = 60.0)
        # create state instance
        s = State(θ₀, γ, dt)

        # time the simulation (at least, the numerical part - which ostensibly takes the longest)
        start_time = time()
        t_analytical, r_analytical, v_analytical = analytical(s)
        t_numerical, r_numerical, v_numerical = numerical(s)
        end_time = time()

        computation_time = end_time - start_time                # calculate computation-time in seconds
        error = get_error(r_analytical, r_numerical)            # calculate error
        error_times_comptime = error * computation_time       # calculate error-computation time product
        impact_point = get_impact_point(r_analytical)  # x-coordinate of impact point

        new(error, computation_time, error_times_comptime,dt, impact_point)
    end
end

function get_impact_point(r_numerical)
    # return x-coordinate at impact
    y_positions = r_numerical[2, :]
    x_positions = r_numerical[1, :]

    # find first index where y > 0 (should be i = 2)
    airborne_idx = findfirst(y -> y > 0, y_positions)

    # find first index/position where y <= 0 (impact)
    impact_idx = findfirst(i -> i > airborne_idx && y_positions[i] <= 0, 1:length(y_positions))
    if impact_idx === nothing
        return NaN  # no impact detected
    else
        # given a slope and the impact idxs, we write our equation in the form y = m(x-x0)
        # solving for x when y=0: x0 = x-(y/m)
        slope = (y_positions[impact_idx] - y_positions[impact_idx-1])/(x_positions[impact_idx] - x_positions[impact_idx-1])
        x_impact_position = x_positions[impact_idx] - y_positions[impact_idx]/slope
            return x_impact_position
    end
end

function run_simulation_with_impact(dt, γ, θ₀)
    # run simulation and return impact point
    s = State(θ₀, γ, dt)
    t_numerical, r_numerical, v_numerical = numerical(s)
    impact_x = get_impact_point(r_numerical)
    return impact_x
end

function numerical_with_thrust(s::State,thrust_magnitude::Float64, thrust_time::Float64)
    # numerical simulation (but w/ rocket boosters this time)
    N = s.N
    a⃗ = eachcol(zeros(2,N))          # preallocate acceleration array
    v⃗ = eachcol(zeros(2,N))          # preallocate velocity array
    r⃗ = eachcol(zeros(2,N))          # preallocate position array

    # initial conditions
    a⃗[1] = s.a₀
    v⃗[1] = s.v₀
    r⃗[1] = s.r₀
    # extract rest of variables from state
    dt = s.dt
    t = s.t⃗
    γ = s.γ

    # run numerical simulation
    for n in 2:N
        current_time = t[n-1]

        # calculate forces
        F_gravity = [0.0, -m*g]
        F_drag = -γ * m * v⃗[n-1]
        F_thrust = [0.0, 0.0] # initialize thrust force

        # add thrust force if within thrust time window
        if current_time <= thrust_time && current_time > 0.0
            # thrust force (in direction of motion)
            v_magnitude = norm(v⃗[n-1])
            if v_magnitude > 0.0
                thrust_direction = v⃗[n-1] / v_magnitude
                F_thrust = thrust_magnitude * thrust_direction
            end
        end

        F_total = F_gravity + F_drag + F_thrust

        v⃗[n] = v⃗[n-1] + (F_total / m) * dt
        a⃗[n] = F_total / m
        r⃗[n] = r⃗[n-1] + v⃗[n-1] * dt
    end

    return t, parent(r⃗), parent(v⃗)
end

function run_simulation_with_thrust(dt, γ, θ₀, thrust_force, thrust_time)
    # run simulation with thrust and return impact point
    s = State(θ₀, γ, dt)
    t_numerical, r_numerical, v_numerical = numerical_with_thrust(s, thrust_force, thrust_time)
    impact_x = get_impact_point(r_numerical)
    return impact_x
end

function find_optimal_dt(errors::Vector{Float64}, dt_values::Vector{Float64})
    threshold_factor = 1.5 # totally arbitrary, but seems to be a pretty good choice
    ∂err∂t = abs.(diff(errors) ./ diff(dt_values))
    min_∂err∂t, min_index = findmin(∂err∂t)
    threshold = threshold_factor * min_∂err∂t # threshold based on minimum derivative

    # find largest dt where derivative is still below threshold ("convergence")
    converged_indices = findall(x -> x <= threshold, ∂err∂t)

    if !isempty(converged_indices)
        optimal_idx = converged_indices[end] + 1  # +1 because, again - diff reduces array size
        return dt_values[optimal_idx], errors[optimal_idx]
    else
        # if no convergence found, return the smallest dt tested
        println("No convergence found! returning finest dt...")
        return dt_values[end], errors[end]
    end
end


