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



nt          = length(data_pt.fields[:ID])
step        = 1000
in2         = collect(1:step:nt)
n_traces    = length(in2)
f_pt        = PassiveTracer_Time( in2, input, dir)

# the following uses PlotlyJS to create an array of traces
data_plot   = Vector{GenericTrace{Dict{Symbol, Any}}}(undef, n_traces);

# fill the tracers using the Pressure-Time paths of the selected passive tracers
for i=1:n_traces

    data_plot[i] = PlotlyJS.scatter(    x               = f_pt.Time_Myrs[2:end],
                                        y               = f_pt.z[i,2:end], 
                                        name            = "Passive tracer #"*"$i",
                                        hoverinfo       = "skip",
                                        mode            = "markers+lines",
                                        marker          = attr( #color   = "black",
                                                                size    = 2.0,),
                                        line            = attr( #color   = "black", 
                                                                width   =  0.75) )
end

layout  = Layout(

    title= attr(
        text    = "Depth-Time path of tracers [Δρ = 700 kg.m⁻³]",
        x       = 0.5,
        xanchor = "center",
        yanchor = "top"
    ),

    yaxis_title = "Depth [km]",
    xaxis_title = "Time [Myrs]",
)

fig = PlotlyJS.plot(data_plot,layout)


