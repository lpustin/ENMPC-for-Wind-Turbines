# ENMPC-for-Wind-Turbines
An Economic Non-linear Model Predictive Controller for Power Production Maximization on Wind Turbines
The controller is deeply described in the following:
Pustina, L., F. Biral, and J. Serafini. "A novel Economic Nonlinear Model Predictive Controller for power maximisation on wind turbines." Renewable and Sustainable Energy Reviews 170 (2022): 112964.

Requirements:
  -a working installation of OpenFAST is required (https://github.com/openfast);
  -a PINS licence to run the precompiled controller is needed.

To achieve the PINS licence, please get in touch with the repository authors.

This repository is divided into 4 folders:
  -in 'ENMPC' is provided the precompiled controller (on Ubuntu 18.04.6 LTS);
  -in 'NREL5MW_inputs' sample OpenFAST input files for the NREL5MW wind turbine controlled with the developed ENMPC are provided;
  -in 'interface' the DLL library to interface the ENMPC and OpenFAST using a socket communication is provided (source and precompiled);
  -in 'post_process_wind_field', a Matlab script to evaluate the effective wind speed is provided.
 
To run the controller, open the terminal in the 'ENMPC' folder and launch the following command:
  python run.py

The controller is now running waiting for OpenFAST; in the 'NREL5MW_inputs' folder, launch OpenFAST:
  openfast RUN_openFAST.fst
