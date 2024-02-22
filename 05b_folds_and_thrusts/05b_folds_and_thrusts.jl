###############################
# 05_folds NR.02-24
# simple setup to simulate folds and thrusts using several isoviscous layers and free surface
# the first layer is very weak and act as decollement layer (salt)
# we use strain-rate boundary condition to impose convergence and a small notch in the center of the simulation to localize defomration

# if you have blue wavy underline below the model definition lines add this to the settings.json in the top left: "julia.lint.call": false
###############################


# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator, GMT, Plots


# directory you want your simulation's output to be saved in
out_dir = "output_medium_S1"

# Below we create a structure to define the modelling setup
model = Model(   
                # Scaling paramters, this ensure non-dimensionalisation in LaMEM but also gives the units to the outputs, you should not have to touch it 
                Scaling(GEO_units(  temperature     = 1000,
                                    stress          = 1e9Pa,
                                    length          = 1km,
                                    viscosity       = 1e19Pa*s) ),

                # This is where you setup the size of your model (as km as set above) and the resolution. e.g., x = [minX, maxX] (...)
                Grid(               x               = [-50.0,50.0],
                                    y               = [-0.25,0.25],               # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [-6.0,2.0],               # Here we change the maximum value of Z in order to account for "air"   
                                    nel             = (320,1,64) ),             # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # sets the conditions at the walls of the modelled domain
                BoundaryConditions( temp_bot        = 20.0,                     # we set temperature, but it is not used in this model
                                    temp_top        = 20.0,
                                    open_top_bound  = 1,                        # we do not want a freesurface, yet!
                                    exx_num_periods = 1,
                                    exx_strain_rates= [-1e-14],
                                    noslip          = [0, 0, 0, 0, 0, 0]),      # [left, right, front, back, bottom, top]

                # set timestepping parameters
                Time(               time_end        = 10.0,                     # Time is always expressed in Myrs (input/output definition)
                                    dt              = 0.001,                     # Target timestep, here 10k years
                                    dt_min          = 0.000001,                 # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 0.01,                      # max dt, here 100k years
                                    nstep_max       = 200,                      # Number of wanted timesteps
                                    nstep_out       = 1 ),                      # save output every nstep_out

                # set solution parameters
                SolutionParams(     eta_min         = 1e18,
                                    eta_ref         = 1e19,
                                    eta_max         = 1e24 ),                  

                FreeSurface(	    surf_use        = 1,                        # free surface activation flag 
                                    surf_corr_phase = 1,                        # air phase ratio correction flag (due to surface position) 
                                    surf_level      = 0.0,                      # initiagn8l level 
                                    surf_air_phase  = 0
                                ),     
                                
                ModelSetup(         advect          = "rk2",                    # advection scheme
                                    interp          = "stag",                   # velocity interpolation scheme
                                    mark_ctrl       = "subgrid",                # marker control type
                                    rand_noise      = 1,
                                    nmark_lim       = [27, 64],                 # min/max number per cell
                                    nmark_sub       = 3 ),

                # what will be saved in the output of the simulation
                Output(             out_density         = 1,
                                    out_melt_fraction   = 1,
                                    out_j2_strain_rate  = 1,
                                    out_temperature     = 1,
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

model.Grid.Phases                      .= 1;                        # here we first define the background phase id = 0, this also defines the first layer
model.Grid.Temp                        .= 20.0;                     # here we first define the background temperature = 20.0

AddBox!(model;  xlim=(model.Grid.coord_x[1], model.Grid.coord_x[2]), 
                ylim=(model.Grid.coord_y[1], model.Grid.coord_y[2]), 
                zlim=(-5.0, 0.0),

                Origin              = nothing,
                StrikeAngle         = 0,
                DipAngle            = 0,
                phase               = ConstantPhase(2),
                T                   = nothing )

Z                                   = model.Grid.Grid.Z;

model.Grid.Phases[Z .> -5.0 .&& Z .<= -4.0 ]    .= 3
model.Grid.Phases[Z .> -3.0 .&& Z .<= -2.0 ]    .= 3
model.Grid.Phases[Z .> -1.0 .&& Z .<= 0.0 ]     .= 3
model.Grid.Phases[Z .> 0.0]                     .= 0;                        # if Z > 0 then we attribute the air phase value 0

# the following part add randomness to the layers interfaces
model.Grid.Phases[Z .> -5.0 .&& Z .<= -5.0 .+ rand.()./4.0 ]    .= 1
model.Grid.Phases[Z .> -4.0 .&& Z .<= -4.0 .+ rand.()./4.0 ]    .= 3
model.Grid.Phases[Z .> -3.0 .&& Z .<= -3.0 .+ rand.()./4.0 ]    .= 2
model.Grid.Phases[Z .> -2.0 .&& Z .<= -2.0 .+ rand.()./4.0 ]    .= 3
model.Grid.Phases[Z .> -1.0 .&& Z .<= -1.0 .+ rand.()./4.0 ]    .= 2


#====================== define material properties of the phases ============================#
softening = Softening(  ID              = 0,   			        # softening law ID
                        APS1            = 0.2, 			        # begin of softening APS
                        APS2            = 0.6, 			        # end of softening APS
                        A               = 0.99  ) 		        # reduction ratio
                       
air = Phase(            Name            = "Air",
                        ID              = 0,
                        rho             = 50, 
                        eta             = 1e18,         
                        G               = 5e10 );

salt = Phase(           Name            = "salt",
                        ID              = 1,             
                        rho             = 2400,      
                        eta             = 1e18,       
                        G               = 5e10 ); 
                        
sediments1 = Phase(     Name            = "sediments1",        
                        ID              = 2, 
                        rho             = 2600,       
                        # eta             = 1e19,      
                        eta             = 1e21,   
                        G               = 5e10,
                        ch              = 10e6,
                        fr              = 10,
                        frSoftID  	    = 0
                         );          

sediments2 = Phase(     Name            = "sediments2",       
                        ID              = 3,              
                        rho             = 2500,           
                        eta             = 1e24,           
                        G               = 5e10,
                        ch              = 20e6,
                        fr              = 20,
                        frSoftID  	    = 0
                         );                 
      

add_phase!( model, air, salt, sediments1,sediments2 )                          # this adds the phases to the model structure, oon't forget to add the air
add_softening!( model,  softening)

plot_cross_section(model, y=0, field=:phase)
savefig("05_folds_and_thrusts.png")
#=============================== perform simulation ===========================================#

run_lamem(model, 8)
