###############################
# read_n_plot.jl NR.02-24
# Routine to import LaMEM output information, retrieve the passive tracers time evolution and plot paths
#
#
###############################

using LaMEM
using PlotlyJS              # here we use PlotlyJS as it gives a bit more flexibility than the default Plots package

dir         = "output" 
input       = "output"

data_pt, time_pt = Read_LaMEM_timestep(input, 1, dir, passive_tracers=true)

# display fields:
keys(data_pt.fields)
# (:Phase, :Temperature, :Pressure, :ID)
# the following gets the ID of the passive tracers of the timestep 1
# data_pt.fields[:ID]

# Oceanic mantle phase = 3

idTracerOP  = findall( data_pt.fields[:Phase] .== 3)
n_traces    = length(idTracerOP)
f_pt        = PassiveTracer_Time( idTracerOP, input, dir)

# the following uses PlotlyJS to create an array of traces
data_plot   = Vector{GenericTrace{Dict{Symbol, Any}}}(undef, n_traces);

# fill the tracers using the Pressure-Time paths of the selected passive tracers
for i=1:n_traces

    data_plot[i] = PlotlyJS.scatter(    x               = f_pt.Temperature[i,2:end],
                                        y               = f_pt.Pressure[i,2:end] ./ 1000.0, 
                                        name            = "Passive tracer #"*"$i",
                                        hoverinfo       = "skip",
                                        mode            = "markers+lines",
                                        marker          = attr( size    = 2.0,),
                                        line            = attr( width   =  0.75) )
end

layout  = Layout(

    title= attr(
        text    = "Pressure-Temperature-time paths tracers",
        x       = 0.5,
        xanchor = "center",
        yanchor = "top"
    ),

    yaxis_title = "Pressure [GPa]",
    xaxis_title = "Temperature [°C]",
)

fig = PlotlyJS.plot(data_plot,layout)




#############################
# Plot convergence velocity #
#############################

idTracers   = [0, 127]          # select first and last trace to compute the evolution of the conrgence velocity
f_pt        = PassiveTracer_Time( idTracers, input, dir)

distance_km = f_pt.x[2,:] - f_pt.x[1,:]
delta_dist  = distance_km[2:end] .- distance_km[1:end-1]
delta_t     = f_pt.Time_Myrs[2:end] .- f_pt.Time_Myrs[1:end-1]
conv_vel    = abs.(delta_dist ./ delta_t) .* 100000.0/1e6


n_traces

data_plot = PlotlyJS.scatter(       x               = f_pt.Time_Myrs[2:end],
                                    y               = conv_vel, 
                                    name            = "Passive tracer #"*"$i",
                                    hoverinfo       = "skip",
                                    mode            = "markers+lines",
                                    marker          = attr( size    = 2.0,),
                                    line            = attr( width   = 0.75) )


layout  = Layout(

    title= attr(
        text    = "Convergence velocity over time",
        x       = 0.5,
        xanchor = "center",
        yanchor = "top"
    ),

    xaxis_title = "Time [Myrs]",
    yaxis_title = "Convergence velocity [cm/yr]",
)

fig = PlotlyJS.plot(data_plot,layout)

