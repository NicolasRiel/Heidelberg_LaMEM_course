###############################
# 05_folds NR.02-24
# Thermal and Mechanical 2D model of subduction.
# The rheologies employed here are iso-viscous. Only the density of the plate are depending on temperature

# if you have blue wavy underline below the model definition lines add this to the settings.json in the top left: "julia.lint.call": false
###############################


# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator, GMT, Plots


# directory you want your simulation's output to be saved in
out_dir = "output"
Tmantle = 1300
Tair    = 20
# Below we create a structure to define the modelling setup
model = Model(   
                # Scaling paramters, this ensure non-dimensionalisation in LaMEM but also gives the units to the outputs, you should not have to touch it 
                Scaling(GEO_units(  temperature     = 1000,
                                    stress          = 1e9Pa,
                                    length          = 1km,
                                    viscosity       = 1e20Pa*s) ),

                # This is where you setup the size of your model (as km as set above) and the resolution. e.g., x = [minX, maxX] (...)
                Grid(               x               = [-1000.0,1000.0],
                                    y               = [-2.0,2.0],               # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [-660.0,30.0],               # Here we change the maximum value of Z in order to account for "air"   
                                    nel             = (256,1,96) ),             # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # sets the conditions at the walls of the modelled domain
                BoundaryConditions( temp_bot        = Tmantle,                     # we set temperature, but it is not used in this model
                                    temp_top        = Tair,
                                    open_top_bound  = 1,                        # we do not want a freesurface, yet!
                                    noslip          = [0, 0, 0, 0, 1, 0]),      # [left, right, front, back, bottom, top]

                # set timestepping parameters
                Time(               time_end        = 40.0,                     # Time is always expressed in Myrs (input/output definition)
                                    dt              = 0.001,                    # Target timestep, here 10k years
                                    dt_min          = 0.000001,                 # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 0.1,                      # max dt, here 100k years
                                    nstep_max       = 400,                      # Number of wanted timesteps
                                    nstep_out       = 4 ),                      # save output every nstep_out

                # set solution parameters
                SolutionParams(     act_temp_diff   = 1,
                                    FSSA            = 1.0,
                                    eta_min         = 1e19,
                                    eta_ref         = 1e20,
                                    eta_max         = 1e24,
                                    init_guess      = 1,                        # initial guess flag
                                    p_lim_plast     = 1),                        # limit pressure at first iteration for plasticity  

                ModelSetup(         advect          = "rk2",                    # advection scheme
                                    interp          = "stag",                   # velocity interpolation scheme
                                    mark_ctrl       = "subgrid",                # marker control type
                                    rand_noise      = 1,
                                    nmark_lim       = [27, 64],                 # min/max number per cell
                                    nmark_sub       = 3 ),

                FreeSurface(	    surf_use        = 1,                        # free surface activation flag 
                                    surf_corr_phase = 1,                        # air phase ratio correction flag (due to surface position) 
                                    surf_level      = 0.0,                      # initial level 
                                    surf_air_phase  = 0,
                                    surf_max_angle  = 40.0 ),   

                PassiveTracers(     Passive_Tracer    = 1,
                                    PassiveTracer_Box = [-900,900,-1,1,-25,-26],
                                    PassiveTracer_Resolution = [128, 1, 1]),  
   
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
                Solver(             SolverType          = "direct",
                                    DirectSolver  	    = "mumps",
                                    PETSc_options       = [ "-snes_rtol 1e-2", "-snes_max_it 100"] )  
            )  

#=================== define phases (different materials) of the model ==========================#

model.Grid.Phases                  .= 1;                        # here we first define the background phase id = 0, this also defines the first layer
model.Grid.Temp                    .= 1300.0;                     # here we first define the background temperature = 20.0

# add overriding plate 
add_box!(model;  xlim    = (-100, 900.0), 
                ylim    = (model.Grid.coord_y[1], model.Grid.coord_y[2]), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=0,
                phase   = LithosphericPhases(Layers=[30 80], Phases=[4 5 1]),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 70      ) )
# add left oceanic plate
add_box!(model;  xlim    = (-900.0, 100.0), 
                ylim    = (model.Grid.coord_y[1], model.Grid.coord_y[2]), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=0,
                phase   = LithosphericPhases(Layers=[20 75], Phases=[2 3 1]),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 70      ) )

# add pre-subducted slab
add_box!(model;  xlim    = (100, 300), 
                ylim    = (model.Grid.coord_y[1], model.Grid.coord_y[2]), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=30,
                phase   = LithosphericPhases(Layers=[20 75], Phases=[2 3 1]),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 60      ) )

Z                                 = model.Grid.Grid.Z;
model.Grid.Temp[Z.>0.0]          .= 20;                        # if Z > 0 then we attribute the air phase value 0



#====================== define material properties of the phases ============================#

           
air = Phase(            Name            = "Air",
                        ID              = 0,
                        rho             = 50, 
                        eta             = 1e19,         
                        G               = 5e10,
                        k               = 100,                      # large conductivity to keep low temperature air
                        Cp              = 1e6  );

Mantle = Phase(         Name            = "Mantle",
                        ID              = 1,             
                        rho             = 3300,      
                        eta             = 1e20,
                        G               = 5e10,
                        alpha           = 3e-5,
                        k               = 3,                        
                        Cp              = 1000,   ); 
                      
OceanCrust = Phase(     Name            = "OceanCrust",
                        ID              = 2,             
                        rho             = 3300,      
                        eta             = 1e23,
                        ch              = 5e6,
                        fr              = 0,
                        G               = 5e10,
                        alpha           = 3e-5,
                        k               = 3,                        
                        Cp              = 1000,   );  
                                            
OceanMantle = Phase(    Name            = "OceanMantle",
                        ID              = 3,             
                        rho             = 3300,      
                        eta             = 1e23,
                        G               = 5e10,
                        ch              = 20e6,
                        fr              = 10,
                        alpha           = 3e-5,
                        k               = 3,                        
                        Cp              = 1000,   );  

ContCrust = Phase(      Name            = "ContCrust",
                        ID              = 4,             
                        rho             = 3000,      
                        eta             = 1e22,
                        G               = 5e10,
                        ch              = 20e6,
                        fr              = 10,
                        alpha           = 3e-5,
                        k               = 3,                        
                        Cp              = 1000,   ); 
                                            
ContMantle = Phase(     Name            = "ContMantle",
                        ID              = 5,             
                        rho             = 3280,      
                        eta             = 1e23,
                        G               = 5e10,
                        ch              = 20e6,
                        fr              = 10,
                        alpha           = 3e-5,
                        k               = 3,                        
                        Cp              = 1000,   ); 



add_phase!( model, air, Mantle, OceanCrust, OceanMantle, ContCrust, ContMantle)                          # this adds the phases to the model structure, oon't forget to add the air

plot_cross_section(model, y=0, field=:phase)
savefig("07_mechanical_subduction_Phase.png")
plot_cross_section(model, y=0, field=:temperature)
savefig("07_mechanical_subduction_T.png")
#=============================== perform simulation ===========================================#

run_lamem(model, 8)
