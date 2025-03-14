# add https://github.com/boriskaus/FastScape.jl

using CSV, DataFrames, ScatteredInterpolation, FastScape, WriteVTK

xl, yl  = 2000.0, 1600.0        # model dimensions in m
nx      = 512*4                 # resolution in x
ny      = 410*4                 # resolution in y
dt      = 100.0                 # time step in years
nstep   = 100                   # number of time steps

erodibility = "high"

if erodibility == "high"
    mean_kf = 100.0e-6
    out         = "Giza_high_Kf"
elseif erodibility == "low"
    mean_kf = 10.0e-6
    out         = "Giza_low_Kf"
end


# Read the CSV file from the Giza topography into a DataFrame
file_path   = "Giza_topo.csv"
df          = CSV.read(file_path, DataFrame)

x_irregular = df.var"Points:0"
y_irregular = df.var"Points:1"
z_irregular = df.var"Points:2"

samples     = z_irregular
points      = hcat(x_irregular, y_irregular)'
itp         = interpolate(NearestNeighbor(), points, samples);

# Define the regular grid
x_regular = range(minimum(x_irregular), stop=maximum(x_irregular), length=nx)
y_regular = range(minimum(y_irregular), stop=maximum(y_irregular), length=ny)

# Create a grid for the regular data
grid_x, grid_y  = [vec(repeat(x_regular', length(y_regular))), vec(repeat(y_regular, 1, length(x_regular)))]
gridPoints      = [grid_x grid_y]'
interpolated    = evaluate(itp, gridPoints)
gridded         = reshape(interpolated, ny, nx)

# Set initial grid size
FastScape_Init()
FastScape_Set_NX_NY(nx,ny)
FastScape_Setup()


FastScape_Set_XL_YL(xl, yl)
x               = range(0, xl, length=nx)
y               = range(0, yl, length=ny)

FastScape_Set_DT(dt)

h               = gridded' .- 12.0 .+ ((rand(nx,ny) .- 0.5).*0.25)
FastScape_Init_H(h)

# Set erosional parameters
kf      = ones(size(h)).*mean_kf

kfsed   = -1.0
m       = 0.4
n       = 1.0
kd      = ones(size(h))*1e-3
kdsed   = -1.0
g       = 0.0
p       = 1.0
FastScape_Set_Erosional_Parameters(kf, kfsed, m, n, kd, kdsed, g, g, p)

# set uplift rate (uniform while keeping boundaries at base level)
u       = ones(size(h))*1e-4
FastScape_Set_U(u[:])

# Set BC's
FastScape_Set_BC(1111)

# echo model setup
FastScape_View()

# initializes time step
istep = FastScape_Get_Step()

# To visualize the results in 3D (In paraview), we need to define 3D arrays:
x2d,y2d = zeros(nx,ny,1), zeros(nx,ny,1)
for I in CartesianIndices(x2d)
    x2d[I], y2d[I] = x[I[1]], y[I[2]]
end

a = zeros(size(h))
d = zeros(size(h))
e = zeros(size(h))
c = zeros(size(h))

z2d = zeros(nx,ny,1);
Kf  = zeros(nx,ny,1);
c2d = zeros(nx,ny,1);
a2d = zeros(nx,ny,1);
TotalErosion = zeros(nx,ny,1)

pvd = paraview_collection(out)
mkpath("VTK")
while istep<nstep
    global istep, pvd, time, x, y

    FastScape_Copy_Total_Erosion(e)

    # execute step
    FastScape_Execute_Step()
    
    # get value of time step counter
    istep = FastScape_Get_Step()
    
    # extract solution
    FastScape_Copy_Catchment(c)
    FastScape_Copy_Drainage_Area(a)

    # create VTK file & add it to pvd file
    z2d[:,:,1] = h
    Kf[:,:,1] = kf
    c2d[:,:,1] = c
    a2d[:,:,1] = a
    TotalErosion[:,:,1] = e
    vtk_grid("VTK/$(out)_$istep", x2d, y2d,z2d) do vtk
        vtk["h [m]"]            = z2d
        vtk["Erodibility "]     = Kf
        vtk["Catchment "]       = c2d
        vtk["Drainage "]        = a2d
        vtk["TotalErosion [m]"] = TotalErosion
        pvd[istep*dt]           = vtk
    end

    # outputs h values
    FastScape_Copy_H(h)
    
    println("step $istep, h-range= $(extrema(h)), nstep=$nstep")    

    kd      = zeros(size(h))
    FastScape_Set_Erosional_Parameters(kf, kfsed, m, n, kd, kdsed, g, g, p)

end

vtk_save(pvd) # save pvd file (open this with Paraview to see an animation)

FastScape_Debug()
FastScape_Destroy()
