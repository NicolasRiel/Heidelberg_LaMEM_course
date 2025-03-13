using FastScape, WriteVTK

# Set initial grid size
m       = 2
xl, yl  = 10e3, 20e3 # model dimensions in m
nx, ny  = 128*m, 256*m
dt      = 1e3
nstep   = 200

x       = range(0, xl, length=nx)
y       = range(0, yl, length=ny)

h       = rand(nx,ny) .-100.0   # same random numbers
h[:,y .> 0.5*yl] .+= 1000.0

u       = zeros(size(h))
u[:,y .> 0.75*yl] .+= 1e-3


erodibility = "high"
if erodibility == "high"
    mean_kf = 100.0e-6
    out         = "M_high_Kf"
elseif erodibility == "low"
    mean_kf = 10.0e-6
    out         = "M_low_Kf"
end


FastScape_Init()
FastScape_Set_NX_NY(nx,ny)
FastScape_Setup()
FastScape_Set_XL_YL(xl, yl)
FastScape_Set_DT(dt)
FastScape_Set_U(u)
FastScape_Set_BC(1000)
FastScape_Init_H(h)

# Set erosional parameters
kf      = ones(nx,ny)*mean_kf
kfsed   = 50e-6
m       = 0.4
n       = 1.0
kd      = ones(nx,ny)*1.5e-3
kdsed   = -1.0
g1      = 1.0
g2      = 1.0
expp    = 1.0
FastScape_Set_Erosional_Parameters(kf, kfsed, m, n, kd, kdsed, g1, g2, expp)
FastScape_View()
istep = FastScape_Get_Step()



# To visualize the results in 3D, we need to define 3D arrays:
a   = zeros(nx,ny)
b   = zeros(nx,ny)
c   = zeros(nx,ny)
x2d,y2d = zeros(nx,ny,1), zeros(nx,ny,1)
for I in CartesianIndices(x2d)
    x2d[I], y2d[I] = x[I[1]], y[I[2]]
end
z2d         = zeros(nx,ny,1);
c2d         = zeros(nx,ny,1);
a2d         = zeros(nx,ny,1);
basement    = zeros(nx,ny,1);

pvd = paraview_collection(out)
mkpath("VTK")
while istep<nstep
    global istep, pvd, time, x, y

    # execute step
    FastScape_Execute_Step()
    istep = FastScape_Get_Step()

    FastScape_Copy_H(h)                 # topography
    FastScape_Copy_Basement(b)          # basement
    FastScape_Copy_Catchment(c)         # Catchment
    FastScape_Copy_Drainage_Area(a)     # Drainage area

    # create VTK file & add it to pvd file
    z2d[:,:,1] = h
    c2d[:,:,1] = c
    a2d[:,:,1] = a
    basement[:,:,1] = b
    vtk_grid("VTK/$(out)_$(istep)", x2d, y2d, z2d) do vtk
        vtk["h [m]"]                    = z2d
        vtk["Sediment thickness [m]"]   = z2d - basement
        vtk["Basement [m]"]             = basement
        vtk["Catchment "]               = c2d
        vtk["Drainage "]                = a2d
        pvd[istep*dt] = vtk
    end
    
    println("step $istep, h-range= $(extrema(h)), nstep=$nstep")    
end

vtk_save(pvd) # save pvd file (open this with Paraview to see an animation)

FastScape_Debug()
FastScape_Destroy()

