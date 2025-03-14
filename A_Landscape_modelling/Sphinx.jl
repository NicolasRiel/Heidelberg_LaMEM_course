# add https://github.com/boriskaus/FastScape.jl

using CSV, DataFrames, ScatteredInterpolation, FastScape, WriteVTK

include("topo_functions.jl")

min_x       = -100.0            # minimum x coordinate in m
max_x       = 100.0             # maximum x coordinate in m
min_y       = 0.0               # minimum y coordinate in m
max_y       = 50.0              # maximum y coordinate in m
xl, yl      = max_x - min_x, max_y - min_y # model dimensions in m
nx          = 1024*2            # resolution in x
ny          = 256*2             # resolution in y      
dt          = 100.0             # time step in years      
nstep       = 100               # number of time steps      

h_layers    = [0.0, 3.0, 4.0, 7.0, 9.0, 12.0, 13.0, 14.0, 15.0].+ 8.0
kf_layers   = [1.0, 10.0, 1.0, 10.0, 1.0, 1.0, 5.0, 1.0] .* mean_kf
tilt_x_alpha= 5.0

erodibility = "high"

if erodibility == "high"
    mean_kf = 100.0e-6
    out         = "Sphinx_high_Kf"
elseif erodibility == "low"
    mean_kf = 10.0e-6
    out         = "Sphinx_low_Kf"
end


x           = collect(range(min_x, max_x, length=nx))
y           = collect(range(min_y, max_y, length=ny))

kf          = zeros(nx,ny)
h           = zeros(nx,ny)
random      = (rand(nx,ny) .- 0.5)


origin_x    = 0.0
for i=1:nx
    
    if x[i] < 50.0
        xp = x[i] - origin_x
        for j=1:ny
            h[i,j] = 23.0 - xp*tan(deg2rad(tilt_x_alpha))
        end
    elseif x[i] > 50.0 && x[i] < 55.0
        xp = x[i] - max_x / 2.0
        for j=1:ny
            h[i,j] = 18.0 - xp*tan(deg2rad(70.0))
        end   
    else
        xp = x[i] - origin_x
        for j=1:ny
            h[i,j] = 8.0 - xp*tan(deg2rad(tilt_x_alpha))
        end
    end
end
h .+=  (rand(nx,ny) .- 0.5).*0.1

update_Kf(      x,y,
                h,kf,
                length(h_layers),
                h_layers ,
                kf_layers, tilt_x_alpha, random; up = 1)


# Set initial grid size
FastScape_Init()
FastScape_Set_NX_NY(nx,ny)
FastScape_Setup()

FastScape_Set_XL_YL(xl, yl)
FastScape_Set_DT(dt)
FastScape_Init_H(h)

kfsed   = -1.0
m       = 0.4
n       = 1.0
kd      = ones(size(h))*5e-5
kdsed   = -1.0
g       = 0.0
p       = 1.0
FastScape_Set_Erosional_Parameters(kf, kfsed, m, n, kd, kdsed, g, g, p)

# set uplift rate (uniform while keeping boundaries at base level)
u       = zeros(size(h))

FastScape_Set_U(u[:])

# Set BC's
FastScape_Set_BC(0101)

# echo model setup
FastScape_View()

# initializes time step
istep = FastScape_Get_Step()

# To visualize the results in 3D (In paraview), we need to define 3D arrays:
x2d,y2d = zeros(nx,ny,1), zeros(nx,ny,1)
for I in CartesianIndices(x2d)
    x2d[I], y2d[I] = x[I[1]], y[I[2]]
end

a       = zeros(size(h))
c       = zeros(size(h))
d       = zeros(size(h))
e       = zeros(size(h))

z2d     = zeros(nx,ny,1);
Kf      = zeros(nx,ny,1);
c2d     = zeros(nx,ny,1);
a2d     = zeros(nx,ny,1);
TotalErosion = zeros(nx,ny,1)

pvd = paraview_collection(out)
mkpath("VTK")
while istep<nstep
    global istep, pvd, time

    FastScape_Copy_Total_Erosion(e)

    update_Kf(      x,y,
                    h,kf,
                    length(h_layers),
                    h_layers ,
                    kf_layers, tilt_x_alpha, random; up = 0)
    FastScape_Set_Erosional_Parameters(kf, kfsed, m, n, kd, kdsed, g, g, p)

    # execute step
    FastScape_Execute_Step()
    
    # get value of time step counter
    istep = FastScape_Get_Step()
    
    # extract solution
    FastScape_Copy_Catchment(c)
    FastScape_Copy_Drainage_Area(a)

    # create VTK file & add it to pvd file
    z2d[:,:,1]  = h
    Kf[:,:,1]   = kf
    c2d[:,:,1]  = c
    a2d[:,:,1]  = a
    TotalErosion[:,:,1] = e
    vtk_grid("VTK/$(out)_$istep", x2d, y2d,z2d) do vtk
        vtk["h [m]"]        = z2d
        vtk["Erodibility "] = Kf
        vtk["Catchment "]   = c2d
        vtk["Drainage "]    = a2d
        vtk["TotalErosion [m]"] = TotalErosion
        pvd[istep*dt]       = vtk
    end
   
    FastScape_Copy_H(h)
    
    println("step $istep, h-range= $(extrema(h)), nstep=$nstep")    
end

vtk_save(pvd) # save pvd file (open this with Paraview to see an animation)

FastScape_Debug()
FastScape_Destroy()
