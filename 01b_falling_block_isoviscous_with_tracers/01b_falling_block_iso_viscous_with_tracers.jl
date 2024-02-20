###############################
# 01_falling_block_iso_viscous NR.02-24
# simple setup to simulate a dense viscous sphere falling down a less viscous medium
#
#
# if you have blue wavy underline below the model definition lines add this to the settings.json in the top left: "julia.lint.call": false
###############################


# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator, GMT, Plots


# directory you want your simulation's output to be saved in
out_dir = "output"

# Below we create a structure to define the modelling setup
model = Model(   
                # Scaling paramters, this ensure non-dimensionalisation in LaMEM but also gives the units to the outputs, you should not have to touch it 
                Scaling(GEO_units(  temperature     = 1000,
                                    stress          = 1e9Pa,
                                    length          = 1km,
                                    viscosity       = 1e20Pa*s) ),

                # This is where you setup the size of your model (as km as set above) and the resolution. e.g., x = [minX, maxX] (...)
                Grid(               x               = [-50.0,50.0],
                                    y               = [-1.0,1.0],               # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [-100.0,0.0],
                                    nel             = (96,1,96) ),              # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # sets the conditions at the walls of the modelled domain
                BoundaryConditions( temp_bot        = 20.0,                     # we set temperature, but it is not used in this model
                                    temp_top        = 20.0,
                                    open_top_bound  = 0,                        # we do not want a freesurface, yet!
                                    noslip          = [0, 0, 0, 0, 0, 0]),      # [left, right, front, back, bottom, top]

                # set timestepping parameters
                Time(               time_end        = 10.0,                     # Time is always expressed in Myrs (input/output definition)
                                    dt              = 0.001,                     # Target timestep, here 10k years
                                    dt_min          = 0.000001,                 # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 0.1,                      # max dt, here 100k years
                                    nstep_max       = 80,                       # Number of wanted timesteps
                                    nstep_out       = 1 ),                      # save output every nstep_out

                # set solution parameters
                SolutionParams(     eta_min         = 1e19,
                                    eta_ref         = 1e20,
                                    eta_max         = 1e22),

                PassiveTracers(     Passive_Tracer      = 1,
                                    PassiveTracer_Box   = [-2.5,2.5,-1,1,-27.5,-22.5]),  
                                    
                # what will be saved in the output of the simulation
                Output(             out_density         = 1,
                                    out_melt_fraction   = 1,
                                    out_j2_strain_rate  = 1,
                                    out_temperature     = 1,
                                    out_surf_velocity   = 1,
                                    out_dir             = out_dir ),

                # here we define the options for the solver, it is advised to no fiddle with this (only comment "-da_refine_y 1" for 3D simulations)
                Solver(             SolverType          = "direct",
                                    DirectSolver  	    = "mumps" )  
            )  

#=================== define phases (different materials) of the model ==========================#

model.Grid.Phases                      .= 0;                        # here we first define the background phase id = 0

AddEllipsoid!(model,    cen             = (0,0,-25),                # defines centre of the sphere
                        axes            = (5,5,5),                  # define size of the sphere
                        StrikeAngle     = 0,
                        DipAngle        = 0,
                        phase           = ConstantPhase(1),         # we attribute phase id = 1, note that this overwrites phase 0 locally
                        T               = ConstantTemp(20));


#====================== define material properties of the phases ============================#

mantle = Phase(         Name            = "Mantle",                 # let's call phase 0 mantle
                        ID              = 0,                        # not that ID here points to phase 0 which is the background phase defined above
                        rho             = 3300,                     # set mantle density
                        eta             = 1e20,                     # set mantle viscosity
                        G               = 5e10 );                   # set elastic modulii

eclogite = Phase(       Name            = "eclogite",
                        ID              = 1,
                        rho             = 4000,
                        eta             = 1e24,
                        G               = 5e10 );

add_phase!( model, mantle, eclogite )                                      # this adds the phases to the model structure

plot_cross_section(model, y=0, field=:phase)
savefig("01b_falling_block_isoviscous_with_tracers.png")
#=============================== perform simulation ===========================================#

run_lamem(model, 2)
