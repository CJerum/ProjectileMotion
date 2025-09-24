module ProjectileMotion

using LinearAlgebra
using StaticArrays

export State, analytical, numerical, get_error

# --- unchanging variables ---
const g = 9.81         # gravitational acceleration in m/s²
const t0 = 0.0         # initial time in seconds
const v0_mag = 600.0   # initial speed (magnitude) in m/s
const r₀ = [0.0, 0.0]  # initial position [x, y] in m
const m = 1.0          # mass of projectile in kg
const tf = 120.0       # final time in seconds

# --- setup architecture for running projectile motion simulations ---
struct State
    r₀::Vector{Float16} # [x,y]
    v₀::Vector{Float16} # [vx,vy]
    a₀::Vector{Float16} # [ax,ay]
    N::Int              # number of time steps
    t⃗::Vector{Float16} # time Vector
    dt::Float16         # timestep
    γ::Float16          # drag coefficient
    θ₀::Float16          # launch angle in degrees

    function State(θ₀, γ, dt)
        r₀_local = r₀
        v₀_local = v0_mag .* [cosd(θ₀), sind(θ₀)]
        a₀_local = [0.0, -g]
        t⃗_local = collect(0:dt:tf)
        N_local = length(t⃗_local)
        θ_local = θ₀
        new(r₀_local, v₀_local, a₀_local, N_local, t⃗_local, dt, γ,θ_local)
    end
end

function analytical(s::State)
    # analytical solution for projectile motion (without drag)
    r₀ = s.r₀
    v₀ = s.v₀
    a₀ = s.a₀
    t⃗ = s.t⃗

    r⃗ = @. r₀ + v₀ * t⃗' + 0.5 * a₀ * (t⃗')^2
    v⃗ = @. v₀ + a₀ * t⃗'

    return t⃗, r⃗, v⃗ # computes a 2xN matrix for r and v, where each column is a time step :)
end

function numerical(s::State)
    # numerical soluition using euler's method
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
    t⃗ = s.t⃗
    γ = s.γ

    # run numerical simulation
    for n in 2:N
        v⃗[n] = v⃗[n-1] + a⃗[n-1]*dt
        a⃗[n] = [0.0, -g] - (γ/m) * v⃗[n-1]
        r⃗[n] = r⃗[n-1] + v⃗[n-1]*dt
    end

    return t⃗, parent(r⃗), parent(v⃗)
end

function get_error(r_analytical, r_numerical)
    # compute the error between analytical and numerical solutions only while y > 0
    above_ground_analytical = r_analytical[2,:] .> 0

    # use only analytical above-ground points for fair comparison
    above_ground = above_ground_analytical

    # compute maximum error only for above-ground points
    error = maximum(norm.(eachcol(r_analytical[:, above_ground] - r_numerical[:, above_ground])))
    return error
end

end 
