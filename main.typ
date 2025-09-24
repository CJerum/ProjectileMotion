#import "@local/homework:1.0.0": *
#set page(paper: "us-letter", margin: (x: 1in, y: 1in))

#homework_setup(title: "Extra Credit Assignment 1",date: "September 26, 2025",course: "PHYS 235")
_I affirm that I did not give or receive any unauthorized help on this assignment, and that this work is my own._
// From Wolfs: Just find the point at which decreasing the timestep doesn't significantly change the result anymore.

Before I get into the first question, I'd like to note that I purposefully set the precision of all kinematic variables to `Float16`, as opposed to `Float32` or `Float64`. The purpose of doing this was so that I may observe effects due to floating point precision without sacrificing a substantial amount of time just waiting around for things to run. This level of floating point precision - `Float16` - will used for all calculations and figures in this assignment.
=== Turn off drag force and set $theta_0$ equal to $60 degree$. Compare the error of the numerical solution as a function of step size `dt`. Based on this plot , determine and optimum value of `dt` to run the simulation.

Based on the graph below, an optimum value of `dt` is around 0.0066 seconds; the error decreases significantly up to this point and then levels off with smaller step sizes. The strange oscillitory behavior at very small step sizes is likely due to numerical precision limits.
#figure(image("figures/error_vs_timestep_60_degrees.png",
	width: 80%),
	caption: [Error of numerical solution as a function of step size `dt` for launch angle $theta_0 = 60 degree$.]
)

==
=== Do the same as before, but this time for two different launch angles ($45 degree " and " 30 degree$), and determine if your optimum value of `dt` depends on launch angle.
As can be seen from the two graphs below, the optimum value of `dt` _does_ depend on launch angle. This makes sense, as a smaller launch angle results in a shorter flight time, and thus requires a finer time resolution to accurately capture the projectile's motion. For a launch angle of 45 degrees, the optimum `dt` is around 0.013 seconds, while for a launch angle of 30 and 60 degrees, the optimum `dt` is around 0.11 and .0066 seconds, respectively.
#figure(image("figures/error_vs_timestep_45_degrees.png",
	width: 80%),
	caption: [Error of numerical solution as a function of step size `dt` for launch angle $theta_0 = 45 degree$.]
)
#figure(image("figures/error_vs_timestep_30_degrees.png",
	width: 80%),
	caption: [Error of numerical solution as a function of step size `dt` for launch angle $theta_0 = 30 degree$.]
)
=== Now, turn on drag force (b = .0005) and set launch angle to $theta = 60 degree$. (When we start including drag force, we can no longer obtain an analytical solution, so we must determine the optimum step size `dt` a different way.) Make a graph of the impact point as a function of `dt`. Determine an optimum value of `dt` based on this graph. (Note: you need to make sure you pick a proper range of `dt` values.)
Based on the below graph, the optimal value of `dt` for $b = .0005$ and $theta  = 60 degree$ is around .000061 seconds. The impact point stabilizes around this value, with smaller step sizes resulting in negligible changes to the impact point. This isn't so unexpected, considering that drag introduces a velocity dependence, which means that any error in the velocity will compound over time, necessitating a finer time resolution to accurately capture the projectile's motion.
#figure(image("figures/PartC_0.0005.png",
	width: 80%),
	caption: [Impact point as a function of step size `dt` for launch angle $theta_0 = 60 degree$ and drag coefficient $b = .0005$.]
)

=== Repeat the previous part for different values of the drag coefficient ($b = .01, .05$). Determine if your optimum value of `dt` depends on the drag coefficient.
While the optimal value of `dt` _does_ depend on the drag coefficient, as expected, I was somewhat surprised to see that a coarser `dt` was sufficient for _higher_ drag coefficients, as opposed to needing finer time resolutions. I suppose we can explain this by realizing that higher drag coefficients result in shorter flight times, which means that the projectile has less time to accumulate error in its trajectory. Thus, a coarser time resolution is sufficient to accurately capture the projectile's motion. For $b = .01$, the optimal `dt` is around .00195 seconds, while for $b = .05$, the optimal `dt` is around .000122 seconds.
#figure(image("figures/PartC_0.01.png",
	width: 80%),
	caption: [Impact point as a function of step size `dt` for launch angle $theta_0 = 60 degree$ and drag coefficient $b = .01$.]
)
#figure(image("figures/PartC_0.05.png",
	width: 80%),
	caption: [Impact point as a function of step size `dt` for launch angle $theta_0 = 60 degree$ and drag coefficient $b = .05$.]
)

=== Set the drag constant to $b=.0005$ and set the launch angle to $theta = 60 degree$. Add a constant thrust force $F$ to the projectile, directed in the direction of motion and acting from $0 < t < T$ (to counter the effect of the drag force). What combination(s) of force $F$ and thrust time $T$ brings the projectile to the impact point it would reach when the only force acting on it would be gravity (i.e., the same impact point as the analytical solution without drag force)?

There is not much to say about this one. I could, I suppose, remark that this figure is certainly my favorite - for it is simply very pretty looking to me. 
#figure(image("figures/PartE_thrust_heatmap.png",
	width: 80%),
	caption: [Impact point as a function of thrust force $F$ and thrust time $T$ for launch angle $theta_0 = 60 degree$ and drag coefficient $b = .0005$. The blue star indicates the combinations of $F$ and $T$ that result in the projectile reaching the impact point closest to where it would without drag. Any combination that lies along the same dark "bend" in the heatmap will result in similarly accurate impact points.]
)

