# LaMEM_course Heidelberg (17-21-25)

Set of input scripts to readily learn how to create more complex input setup for LaMEM@0.4.5 (https://github.com/JuliaGeodynamics/LaMEM.jl)

## Report

Individual report: 3 pages of text max (figures not included)

* **Scientific questions**: What are you trying to answer/solve? Why this model setup? How can the model setup can help solve the questions? What are the parameters that need to be investigated?
*  **Modelling approach**: Model setup, geometry, boundary conditions (top, bottom, etc), thermal and mechanical material properties and investigated parameters.
* **Modelling results**: Describe modelling results, including figures produced using paraview.
* **Discussion/perspectives**: What did you learn? What are the limitations? How can it be improved? What would be the next step?
How do the models compare to a real/natural case?

> [!IMPORTANT] 
> For the figures make sure you have the axis properly labelled, provide colorbar and caption for all fields and contour/glyphs. Annotate time (CTRL+SPACE Annotate time)
> Explore the control of 1 or 2 parameters
> Hand-over March 29th - 2024
> Attach the Julia script to your report (send per mail)

## Explored setups

### Day 1

| Falling blocks 3D         | Falling block 2D     |
|--------------|-----------|
| <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/00_falling_block_3D.gif?raw=true" alt="drawing" width="380" alt="centered image"/> | <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/01_falling_block_isoviscous.gif?raw=true" alt="drawing" width="380" alt="centered image"/>  |

### Day 2

| Falling block - free surface 2D         | Plume emplacement - stagnant LID 2D    |
|--------------|-----------|
| <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/03_T-falling_block_iso_viscous_free_surface.gif?raw=true" alt="drawing" width="380" alt="centered image"/> | <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/04b_single_LID_plume_with_tracers.gif?raw=true" alt="drawing" width="380" alt="centered image"/>  |

### Day 3


| Folding 2D         | Rifting 2D    |
|--------------|-----------|
| <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/05_folds.gif?raw=true" alt="drawing" width="380" alt="centered image"/> | <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/06_rifting_model_plasticity.gif?raw=true" alt="drawing" width="380" alt="centered image"/>  |

### Day 4
 | Subduction 2D         |  Landscape Modelling  |
|--------------|-----------|
| <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/07_mechanical_subduction.gif?raw=true" alt="drawing" width="380" alt="centered image"/> |  <img src="https://github.com/NicolasRiel/Heidelberg_LaMEM_course/blob/main/gifs/mountain_landscape.gif?raw=true" alt="drawing" width="380" alt="centered image"/> |

## Tools and tipds

####  Introduction for Julia programming language

    Julia_introduction/IntroJulia.md

####  Density diagrams for general rock-types

    phase_diagrams_4_LaMEM/

####  create gif from *.png

    sudo apt-get install imagemagick
    convert -delay 2 -loop 0 *.png 01.gif  -scale 584x626 gif_name.gif


### LaMEM creep laws list


#### Diffusion creep:

[Hirth, G. & Kohlstedt (2003), D. Rheology of the upper mantle and the mantle wedge: A view from the experimentalists]

+ "Dry_Olivine_diff_creep-Hirth_Kohlstedt_2003"
+ "Wet_Olivine_diff_creep-Hirth_Kohlstedt_2003_constant_C_OH"
+ "Wet_Olivine_diff_creep-Hirth_Kohlstedt_2003"
 
[Rybacki and Dresen, 2000, JGR]

+ "Dry_Plagioclase_RybackiDresen_2000"
+ "Wet_Plagioclase_RybackiDresen_2000"

#### Dislocation creep:

[Ranalli 1995]

+ "Dry_Olivine-Ranalli_1995"
+ "Wet_Olivine-Ranalli_1995"
+ "Wet_Quarzite-Ranalli_1995"
+ "Quarzite-Ranalli_1995"
+ "Mafic_Granulite-Ranalli_1995"
+ "Plagioclase_An75-Ranalli_1995"
  
[Carter and Tsenn (1986). Flow properties of continental lithosphere - page 18]

+ "Quartz_Diorite-Hansen_Carter_1982"
  
[J. de Bremond d'Ars et al./Tectonophysics (1999). Hydrothermalism and Diapirism in the Archaean: gravitational instability constrains. - page 5]

+ "Diabase-Caristan_1982"
+ "Tumut_Pond_Serpentinite-Raleigh_Paterson_1965"
  
[Mackwell, Zimmerman & Kohlstedt (1998). High-temperature deformation]

+ "Maryland_strong_diabase-Mackwell_et_al_1998"
  
[Ueda et al (PEPI 2008)]

+ "Wet_Quarzite-Ueda_et_al_2008"
  
[Huismans et al 2001]

+ "Diabase-Huismans_et_al_2001"
+ "Granite-Huismans_et_al_2001"
  
[Burg And Podladchikov (1999)]

+ "Dry_Upper_Crust-Schmalholz_Kaus_Burg_2009"
+ "Weak_Lower_Crust-Schmalholz_Kaus_Burg_2009"
+ "Olivine-Burg_Podladchikov_1999"
  
[Rybacki and Dresen, 2000, JGR]

+ "Dry_Plagioclase_RybackiDresen_2000"
+ "Wet_Plagioclase_RybackiDresen_2000"
  
[Hirth, G. & Kohlstedt (2003), D. Rheology of the upper mantle and the mantle wedge: A view from the experimentalists]

+ "Wet_Olivine_disl_creep-Hirth_Kohlstedt_2003"
+ "Wet_Olivine_disl_creep-Hirth_Kohlstedt_2003_constant_C_OH"
+ "Dry_Olivine_disl_creep-Hirth_Kohlstedt_2003"
  
[SchmalholzKausBurg(2009), Geology (wet olivine)]

+ "Wet_Upper_Mantle-Burg_Schmalholz_2008"
+ "Granite-Tirel_et_al_2008"

[Urai et al.(2008)]

+ "Ara_rocksalt-Urai_et_al.(2008)"
  
[Bräuer et al. (2011) Description of the Gorleben site (PART 4): Geotechnical exploration of the Gorleben salt dome - page 126]

+ "RockSaltReference_BGRa_class3-Braeumer_et_al_2011"
  
[Mueller and Briegel (1978)]

+ "Polycrystalline_Anhydrite-Mueller_and_Briegel(1978)"

#### Peierls creep:

[Guyot and Dorn (1967) and Poirier (1985)]

+ "Olivine_Peierls-Kameyama_1999"

## Velocity box
The code snipped shows how to add a velocity box to a LaMEM model.

    vel_box = VelocityBox(      cenX     =   1.0,  # X-coordinate of center of box
                                cenY     =   1.0,  # Y-coordinate of center of box
                                cenZ     =   1.0,  # Z-coordinate of center of box
                                widthX   =   1.0,  # Width of box in x-direction
                                widthY   =   2.0,  # Width of box in y-direction
                                widthZ   =   0.1,  # Width of box in z-direction
                                vx       =   1.0,  # Vx velocity of box (default is unconstrained)
                                vy       =   0.0,  # Vy velocity of box (default is unconstrained)
                                vz       =   0.0,  # Vz velocity of box (default is unconstrained) 
                                advect   =   0)    # box advection flag

    add_vbox!(model, vel_box)


## Inflow - outflow boundary conditions (left-right walls)
Simple example on how to set in flow/outflow boundary conditions on left and right walls for the lithosphere

    model.BoundaryConditions = BoundaryConditions(  bvel_face                 =         "Left",                         # Face identifier  (Left; Right; Front; Back; CompensatingInflow)
                                                    bvel_face_out             =         1,                            # Velocity on opposite side: -1 for inverted velocity; 0 for no velocity; 1 for the same direction of velocity
                                                    bvel_bot                  =        -100.0,                         # bottom coordinate of inflow window
                                                    bvel_top                  =        0.0,                         # top coordinate of inflow window
                                                    bvel_velin                =         1.0,              # inflow velocity for each time interval(Multiple values required if  velin_num_periods>1)
                                                    bvel_velout               =         1.0)                         # outflow velocity (if not specified, computed from mass balance)

## Add topography to LaMEM
Example showing how to load Askja volcano topography to LaMEM

    Topo = import_topo( lat=[64.55,65.55],
                        lon=[-18.0+360,-15.6+360],
                        file="@earth_relief_15s.grd")

    # choose projection point (center usually)                       
    proj = ProjectionPoint( Lon     = -16.8,
                            Lat     =  65.05);

    Topo_cart = convert2CartData(Topo, proj)

    # Create a grid to be saved
    Topo_LaMEM = CartData(xyz_grid(-20:.2:20,
                                -20:.2:20,
                                0         )); 

    Topo_LaMEM = project_CartData(   Topo_LaMEM,
                                    Topo, 
                                    proj    )


## Add ridge to add_box!

    add_box!(model;  xlim    = (-2000.0, 0.0), 
                    ylim    = (model.Grid.coord_y...,), 
                    zlim    = (-660.0, 0.0),
                    Origin  = nothing, StrikeAngle=0, DipAngle=0,
                    phase   = LithosphericPhases(Layers=[20 80], Phases=[1 2 0] ),
                    T       = SpreadingRateTemp(    Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    MORside     = "left",
                                                    SpreadingVel= 0.5,
                                                    AgeRidge    = 0.01;
                                                    maxAge      = 80.0      ) )