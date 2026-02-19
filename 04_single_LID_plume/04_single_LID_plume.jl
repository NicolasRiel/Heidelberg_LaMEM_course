###############################
# 04_single_LID_convection NR.02-24
# simple setup to simulate single lid plume emplacement
# 
#
# if you have blue wavy underline below the model definition lines add this to the settings.json in the top left: "julia.lint.call": false
###############################


# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator, GMT, Plots


# directory you want your simulation's output to be saved in
out_dir = "output_creep"

# Below we create a structure to define the modelling setup
model = Model(   
                # Scaling paramters, this ensure non-dimensionalisation in LaMEM but also gives the units to the outputs, you should not have to touch it 
                Scaling(GEO_units(  temperature     = 1000,
                                    stress          = 1e9Pa,
                                    length          = 1km,
                                    viscosity       = 1e20Pa*s) ),

                # This is where you setup the size of your model (as km as set above) and the resolution. e.g., x = [minX, maxX] (...)
                Grid(               x               = [-500.0,500.0],
                                    y               = [-1.0,1.0],               # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [-660.0,50.0],            # Here we change the maximum value of Z in order to account for "air"   
                                    nel             = (96,1,96) ),              # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # sets the conditions at the walls of the modelled domain
                BoundaryConditions( temp_top        = 20.0,
                                    temp_bot        = 1590.0, 
                                    open_top_bound  = 1,                        # we do not want a freesurface, yet!
                                    noslip          = [0, 0, 0, 0, 0, 0]),      # [left, right, front, back, bottom, top]
                                
                ModelSetup(         advect          = "rk2",                    # advection scheme
                                    interp          = "stag",                   # velocity interpolation scheme
                                    mark_ctrl       = "subgrid",                # marker control type
                                    rand_noise      = 1,
                                    nmark_lim       = [27, 64],                 # min/max number per cell
                                    nmark_sub       = 3 ),

                # set timestepping parameters
                Time(               time_end        = 20.0,                     # Time is always expressed in Myrs (input/output definition)
                                    dt              = 0.001,                     # Target timestep, here 10k years
                                    dt_min          = 0.000001,                 # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 0.1,                      # max dt, here 100k years
                                    nstep_max       = 600,                       # Number of wanted timesteps
                                    nstep_out       = 1 ),                      # save output every nstep_out

                PassiveTracers(     Passive_Tracer    = 1,
                                    PassiveTracer_Box = [-60,60,-1,1,-660,-540],
                                    PassiveTracer_Resolution = [64, 1, 64]),  
   
                # set solution parameters
                SolutionParams(     eta_min         = 1e19,
                                    eta_ref         = 1e20,
                                    eta_max         = 1e23, 
                                    act_temp_diff   = 1,                        # activate Temperature diffusion
                                    shear_heat_eff  = 1.0,                      # shear heating 
                                    Adiabatic_Heat  = 1.0,                      # adiabatic heating 
                                    FSSA            = 1.0 ),                    # activate Free Surface Stabilization Algorithm  

                FreeSurface(	    surf_use        = 1,                        # free surface activation flag 
                                    surf_corr_phase = 1,                        # air phase ratio correction flag (due to surface position) 
                                    surf_level      = 0.0,                      # initial level 
                                    surf_air_phase  = 0,                        # phase ID of sticky air layer 
                                    surf_max_angle  = 40.0                      # maximum angle with horizon (smoothed if larger)) 
                                ),         
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
                                    PETSc_options       = [ "-snes_rtol 1e-2"] )  
            )  

#=================== define phases (different materials) of the model ==========================#

Tair                    = 20.0;
Tmantle                 = 1280.0;
model.Grid.Temp        .= Tmantle;              # set mantle temperature (without adiabat at first)

# add single plate using Addbox!
AddBox!(model;  xlim    = (model.Grid.coord_x[1], model.Grid.coord_x[2]), 
                ylim    = (model.Grid.coord_y[1], model.Grid.coord_y[2]), 
                zlim    = (model.Grid.coord_z[1], 0.0),

                Origin  = nothing, StrikeAngle=0, DipAngle=0,

                phase   = LithosphericPhases(       Layers=[30 90], 
                                                    Phases=[1 2 3] ),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 100      ))

Z                       = model.Grid.Grid.Z;
X                       = model.Grid.Grid.X;
Adiabat                 = 0.5                   # 0.5°C/km
model.Grid.Temp         = model.Grid.Temp -Z.*Adiabat;

model.Grid.Phases[model.Grid.Temp .> Tmantle ]  .= 3;
model.Grid.Phases[Z.>0.0]                       .= 0;                        # if Z > 0 then we attribute the air phase value 0
model.Grid.Temp[Z.>0.0]                         .= 20.0;   

# here we define a plume by increasing the temperature of the mantle within a circle
center                  = [0.0,-600]
radius                  = 100.0
in_sphere               = findall( (X .- center[1]).^2 .+ (Z .- center[2]).^2 .<= radius^2 )
model.Grid.Temp[in_sphere]      .+= 100.0
model.Grid.Phases[in_sphere]    .= 4

#====================== define material properties of the phases ============================#
air = Phase(            Name            = "Air",
                        ID              = 0,
                        k               = 100,                      # large conductivity to keep low temperature air
                        Cp              = 1e6,                      # heat capacity   
                        rho             = 50,                       # prescribe a relatively low density for the air. Mind that realistic density for the air may lead to numerical instability
                        eta             = 1e20,                     # here we set the viscosity on the air as the minimum viscosity in our simulation, so the one of the mantle
                        G               = 5e10 )

crust = Phase(          Name            = "crust",                 # let's call phase 0 mantle
                        ID              = 1,                        # not that ID here points to phase 0 which is the background phase defined above
                        alpha           = 3e-5,
                        k               = 3,                        # conductivity 
                        Cp              = 1000,                     # heat capacity 
                        rho             = 2800,                     # set mantle density
                        rho_ph          = "../ContinentalCrust",
                        # eta             = 1e20,
                        disl_prof       = "Quarzite-Ranalli_1995",
                        G               = 5e10 );
              
mantle = Phase(         Name            = "Mantle",                 # let's call phase 0 mantle
                        ID              = 2,                        # not that ID here points to phase 0 which is the background phase defined above
                        alpha           = 3e-5,
                        k               = 3,                        # conductivity 
                        Cp              = 1000,                     # heat capacity 
                        rho             = 3300,                     # set mantle density
                        G               = 5e10,
                        # eta             = 1e23,
                        disl_prof       = "Dry_Olivine_disl_creep-Hirth_Kohlstedt_2003",
                        diff_prof       = "Dry_Olivine_diff_creep-Hirth_Kohlstedt_2003" );

asthenosphere = copy_phase(     mantle,
                                Name    = "asthenosphere",
                                # eta             = 5e20,
                                ID      = 3 );

plume = copy_phase(             mantle,
                                Name    = "plume",
                                # eta             = 5e20,
                                rho             = 3280.0,
                                ID      = 4 );


add_phase!( model, air, crust, mantle, asthenosphere, plume )                          # this adds the phases to the model structure, oon't forget to add the air

plot_cross_section(model, y=0, field=:phase)
savefig("04_single_LID_plume_phase.png")
plot_cross_section(model, y=0, field=:temperature)
savefig("04_single_LID_plume_temp.png")
#=============================== perform simulation ===========================================#

run_lamem(model, 4)
