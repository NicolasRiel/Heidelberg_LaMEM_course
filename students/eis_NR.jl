# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator, GMT, Plots


# directory you want your simulation's output to be saved in
out_dir = "output"

# Below we create a structure to define the modelling setup
model = Model(   
                # dont touch
                Scaling(GEO_units(  temperature     = 1000,
                                    stress          = 1e9Pa,
                                    length          = 1km,
                                    viscosity       = 1e20Pa*s) ),

                # model size, 2d
                Grid(               x               = [-50.0,50.0],
                                    y               = [-1.0,1.0],               # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [-100.0,20.0],
                                    nel             = (96,1,96) ),              # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # boundary
                BoundaryConditions( temp_bot        = 20.0,                     # we set temperature, but it is not used in this model
                                    temp_top        = 20.0,
                                    open_top_bound  = 1,                        # we do not want a freesurface, yet!
                                    noslip          = [0, 0, 0, 0, 1, 0]),      # 0 frei, 1 fixiert [left, right, front, back, bottom, top]

                # set timestepping parameters
                Time(               time_end        = 10.0,                     # Time is always expressed in Myrs (input/output definition)
                                    dt              = 0.001,                     # Target timestep, here 10k years
                                    dt_min          = 0.000001,                 # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 0.1,                      # max dt, here 100k years
                                    nstep_max       = 100,                       # Number of wanted timesteps
                                    nstep_out       = 1 ),                      # save output every nstep_out

                # set solution parameters
                SolutionParams(     eta_min         = 1e19,
                                    eta_ref         = 1e20,
                                    eta_max         = 1e22),

                FreeSurface(	    surf_use        = 1,                        # free surface activation flag 
                                    surf_corr_phase = 0,                        # air phase ratio correction flag (due to surface position) 
                                    surf_level      = 0.0,                      # initial level 
                                    surf_air_phase  = 3,                        # phase ID of sticky air layer 
                                    surf_max_angle  = 40.0 ),                     # maximum angle with horizon (smoothed if larger))   
                           
                                    # what will be saved in the output of the simulation
                Output(             out_density         = 1,
                                    out_melt_fraction   = 1,
                                    out_j2_strain_rate  = 1,
                                    out_temperature     = 1,
                                    out_surf_velocity   = 1,
                                    out_dir             = out_dir ),

                # dont touch
                Solver(             SolverType          = "direct",
                                    DirectSolver  	    = "mumps" )  
            )  
#=================== define phases (different materials) of the model ==========================#

# Setze den gesamten Hintergrund auf Mantel (Phase 0)
model.Grid.Phases .= 0;

# **Mantel (Phase 0)**
add_box!(model,  
         xlim = (-50, 50),  
         ylim = (-1, 1),  
         zlim = (-100, -20),  # Mantel erstreckt sich bis -100 km
         phase = ConstantPhase(0));  

# **Kruste (Phase 1)**
add_box!(model,  
         xlim = (-50, 50),  
         ylim = (-1, 1),  
         zlim = (-20, 0),  # Kruste von -20 km bis zur Oberfläche (0 km)
         phase = ConstantPhase(1));

# **Luft (Phase 3)**
add_box!(model,  
         xlim = (-50, 50),  
         ylim = (-1, 1),  
         zlim = (0, 20),  # Luft von 10 km bis 20 km Höhe
         phase = ConstantPhase(3));  


 # **Eis (Phase 2)**
add_box!(model,  
        xlim = (-50, 0),  
        ylim = (-1, 1),  
        zlim = (-5, 0),  # 10km dick
        phase = ConstantPhase(2));

add_box!(model,  
         xlim = (0, 50),  
         ylim = (-1, 1),  
         zlim = (-5, 0),  # Luft von 10 km bis 20 km Höhe
         phase = ConstantPhase(1));  


mantle = Phase(  Name = "Mantle", ID = 0, rho = 3300, eta = 1e15, G = 5e10 );  # eher zu flüssig
crust  = Phase(  Name = "Crust",  ID = 1, rho = 2800, eta = 1e15, G = 5e10 );  # eher zu flüssig
ice    = Phase(  Name = "Ice",    ID = 2, rho = 1000, eta = 1e28, G = 5e10 ); # eisparameter extrem
air    = Phase(  Name = "Air",    ID = 3, rho = 50,  eta = 1e20, G = 1e5 );    # air parameter analog nicolas 

add_phase!(model, mantle, crust, ice, air);  # Phasen zum Modell hinzufügen

# **Phasenübergang: Eis (2) → Luft (3) nach 5 Myr**
phaseT = PhaseTransition(
    ID                  = 0,                  # Eindeutige ID für diese Phasenregel
    Type                = "Constant",         # Einfache Übergangsbedingung
    Parameter_transition = "t",               # Übergang basierend auf Zeit
    ConstantValue       = 0.1,                # Nach 5 Myr erfolgt die Umwandlung
    number_phases       = 1,                  # Eine Phase wird verändert
    PhaseBelow          = [2],                # Eis (Phase 2) existiert vor dem Übergang
    PhaseAbove          = [1],                # Nach dem Übergang wird es Luft (Phase 3)
    PhaseDirection      = "BelowToAbove"       # Nach Erreichen von 5 Myr wechselt Phase 2 → 3
)

# here phase below should another air (not the one you use for air), call it air2 for instance
# I was using the crust for debugging purposes


# **Phasenübergang zum Modell hinzufügen**
add_phasetransition!(model, phaseT)


# **Cross-Section Plot erstellen & speichern**
plot_cross_section(model, y=0, field=:phase)
savefig("projekt.png")

# **Simulation starten**
run_lamem(model, 4)
