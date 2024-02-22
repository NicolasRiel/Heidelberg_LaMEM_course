###############################
# 08_Volcano_askja.jl NR.02-24
# Thermo-mechanical setup to mode uplift of the Askja Volcano in Iceland
# 
# This setup uses the Package GeophysicalModelGenerator to import topography
# Have a look here: 
# https://github.com/JuliaGeodynamics/GeophysicalModelGenerator.jl
# https://juliageodynamics.github.io/GeophysicalModelGenerator.jl/dev/

# !! Sometimes GMT bugs !!

# if you have blue wavy underline below the model definition lines add this to the settings.json in the top left: "julia.lint.call": false
###############################

# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator, GMT, Plots, JLD2

# directory you want your simulation's output to be saved in
out_dir = "output"
Tmantle = 1000
Tair    = 20


if ~isfile("topo.jld2")
  print("using GMT to import surface topography\n")
  # import topography using GMT at given dd coordinates:
  Topo = ImportTopo(      lon     =  [-18.0, -15.6],
                          lat     =  [64.55, 65.55],
                          file    = "@earth_relief_15s.grd");
  
  # choose projection point (center usually)                       
  proj = ProjectionPoint( Lon     = -16.8,
                          Lat     =  65.05);
  
  Topo_cart = Convert2CartData(Topo, proj)
  
  # Create a grid to be saved
  Topo_LaMEM = CartData(XYZGrid(-20:.2:20,
                                -20:.2:20,
                                0         )); 
  
  Topo_LaMEM = ProjectCartData(   Topo_LaMEM,
                                  Topo, 
                                  proj    )
  
  plot_topo(Topo_LaMEM, clim=(-2,2))
  
  savefig("08_Volcano_Askja.png")
  save_object("topo.jld2",Topo_LaMEM)
else
  Topo_LaMEM = load_object("topo.jld2")
end


# Below we create a structure to define the modelling setup
model = Model(   
                # Scaling paramters, this ensure non-dimensionalisation in LaMEM but also gives the units to the outputs, you should not have to touch it 
                Scaling(GEO_units(  temperature     = 1000,
                                    stress          = 1e9Pa,
                                    length          = 1km,
                                    viscosity       = 1e18Pa*s) ),

                # This is where you setup the size of your model (as km as set above) and the resolution. e.g., x = [minX, maxX] (...)
                Grid(               x               = [-16.0,16.0],
                                    y               = [-0.2,0.2],             # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [-16.0,4.0],              # Here we change the maximum value of Z in order to account for "air"   
                                    nel             = (128,2,64) ),             # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # sets the conditions at the walls of the modelled domain
                BoundaryConditions( temp_bot        = Tmantle,                  # we set temperature, but it is not used in this model
                                    temp_top        = Tair,
                                    open_top_bound  = 1,                        # we do not want a freesurface, yet!
                                    exx_num_periods = 1,
                                    exx_strain_rates= [5e-16]),                 # Iceland is a rift!

                # set timestepping parameters
                Time(               time_end        = 1.0,                      # Time is always expressed in Myrs (input/output definition)
                                    dt              = 0.00001,                    # Target timestep, here 10k years
                                    dt_min          = 0.0000001,                  # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 0.1,                     # max dt, here 100k years
                                    nstep_max       = 80,                       # Number of wanted timesteps
                                    nstep_out       = 1 ),                      # save output every nstep_out

                # set solution parameters
                SolutionParams(     act_temp_diff   = 1,
                                    FSSA            = 1.0,
                                    eta_min         = 1e16,
                                    eta_ref         = 1e19,
                                    eta_max         = 1e21,
                                    init_guess      = 1,                        # initial guess flag
                                    p_lim_plast     = 1),                       # limit pressure at first iteration for plasticity  

                ModelSetup(         advect          = "rk2",                    # advection scheme
                                    interp          = "stag",                   # velocity interpolation scheme
                                    mark_ctrl       = "subgrid",                # marker control type
                                    rand_noise      = 1,
                                    nmark_lim       = [27, 64],                 # min/max number per cell
                                    nmark_sub       = 3 ),

                FreeSurface(	      surf_use        = 1,                        # free surface activation flag 
                                    surf_corr_phase = 1,                        # air phase ratio correction flag (due to surface position) 
                                    surf_level      = 0.0,                      # initial level 
                                    surf_air_phase  = 0,
                                    surf_max_angle  = 40.0 ),   

                # what will be saved in the output of the simulation
                Output(             out_density         = 1,
                                    out_melt_fraction   = 1,
                                    out_j2_strain_rate  = 1,
                                    out_temperature     = 1,
                                    out_pressure        = 1,
                                    out_surf            = 1,              
                                    out_surf_velocity   = 1,             	
                                    out_surf_pvd        = 1,  
                                    out_surf_topography = 1,
                                    out_dir             = out_dir ),

                # here we define the options for the solver, it is advised to no fiddle with this (only comment "-da_refine_y 1" for 3D simulations)
                Solver(             SolverType          = "multigrid",
                                    MGLevels            = 3,
                                    MGCoarseSolver  	  = "mumps",
                                    PETSc_options       = [ "-snes_ksp_ew",
                                                            "-snes_ksp_ew_rtolmax 1e-4",
                                                            "-snes_rtol 1e-2",			
                                                            "-snes_atol 1e-4",
                                                            "-snes_max_it 200",
                                                            "-da_refine_y 1",   # comment this line for 3D models
                                                            "-snes_PicardSwitchToNewton_rtol 1e-2", 
                                                            "-snes_NewtonSwitchToPicard_it 20",
                                                            "-js_ksp_type fgmres",
                                                            "-js_ksp_max_it 20",
                                                            "-js_ksp_atol 1e-8",
                                                            "-js_ksp_rtol 1e-4",
                                                            "-snes_linesearch_type l2",
                                                            "-snes_linesearch_maxstep 10",
                                                            ])
            )  

#=================== define phases (different materials) of the model ==========================#
Z                  = model.Grid.Grid.Z;
model.Grid.Phases .= 1;                        # here we first define the background phase id = 0, this also defines the first layer
model.Grid.Temp   .= Tair                      # here we first define the background temperature = 20.0

AboveSurface!(  model,
                Topo_LaMEM,
                phase = 0,
                T     = 20 )


# here we define a geotherm and apply it

Geotherm           = 25
model.Grid.Temp    = -Z.*Geotherm;

AddEllipsoid!(model, cen=(0,0,-6.5),  axes=(6,6,4),   StrikeAngle=0, DipAngle=0, phase=ConstantPhase(2), T=ConstantTemp(900));
AddEllipsoid!(model, cen=(0,0,-3.75), axes=(2.0,2.0,1.5), StrikeAngle=0, DipAngle=0, phase=ConstantPhase(3), T=ConstantTemp(900));


model.Grid.Phases[Z.<-0 .&& model.Grid.Phases .== 0]  .= 1;

#====================== define material properties of the phases ============================#

phaseT = PhaseTransition( ID            = 0,
                          Type          = "Constant",
                          Parameter_transition = "t",
                          ConstantValue = 0.05,
                          number_phases = 2,
                          PhaseBelow    = [2,3],
                          PhaseAbove    = [4,5],
                          PhaseDirection= "BelowToAbove" );         # BelowToAbove -> Below ConstantValue, Above ConstantValue. If constant value value is t, it means that below t are the phase prescribed before phase change
                        
air = Phase(            Name            = "Air",
                        ID              = 0,
                        rho             = 50, 
                        eta             = 1e18,         
                        G               = 5e10,
                        k               = 100,                      # large conductivity to keep low temperature air
                        Cp              = 1e6  );

Crust = Phase(          Name            = "Crust",
                        ID              = 1,             
                        rho             = 2800,      
                        eta             = 1e21,
                        ch              = 10e6,
                        fr              = 10,
                        G               = 5e10,
                        alpha           = 3e-5,
                        k               = 3,                        
                        Cp              = 1000 );   
                      
MagmaCrust  = copy_phase(Crust,   ID = 2, Name = "MagmaCrust")
GasCrust    = copy_phase(Crust,   ID = 3, Name = "GasCrust")

Magma       = copy_phase(Crust,   ID = 4, Name = "Magma", eta=5e16, rho=2100.0)
Gas         = copy_phase(Crust,   ID = 5, Name = "Gas",   eta=1e16, rho=10.0)

add_phase!( model, air, Crust, MagmaCrust, GasCrust, Magma, Gas)                          # this adds the phases to the model structure, oon't forget to add the air
add_topography!(model, Topo_LaMEM)
add_phasetransition!(model, phaseT)

plot_cross_section(model, y=0, field=:phase)
savefig("08_Volcano_Askja_Phase.png")
plot_cross_section(model, y=0, field=:temperature)
savefig("08_Volcano_Askja_T.png")
#=============================== perform simulation ===========================================#

run_lamem(model, 8)
