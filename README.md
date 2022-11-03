# ENMPC-for-Wind-Turbines
An Economic Non-linear Model Predictive Controller for Power Production Maximization on Wind Turbines
The controller is deeply described in the following:<br />
Pustina, L., F. Biral, and J. Serafini. "A novel Economic Nonlinear Model Predictive Controller for power maximisation on wind turbines." Renewable and Sustainable Energy Reviews 170 (2022): 112964.<br />

Requirements:<br />
  -a working installation of OpenFAST is required (https://github.com/openfast);<br />
  -a PINS licence to run the precompiled controller is needed.<br />

To achieve the PINS licence, please get in touch with the repository authors.<br />

This repository is divided into 4 folders:<br />
  -in 'ENMPC' is provided the precompiled controller (on Ubuntu 18.04.6 LTS);<br />
  -in 'NREL5MW_inputs' sample OpenFAST input files for the NREL5MW wind turbine controlled with the developed ENMPC are provided;<br />
  -in 'interface' the DLL library to interface the ENMPC and OpenFAST using a socket communication is provided (source and precompiled);<br />
  -in 'post_process_wind_field', a Matlab script to evaluate the effective wind speed is provided.<br />
 <br />
To run the controller, open the terminal in the 'ENMPC' folder and launch the following command:<br />
  python run.py<br />

The controller is now running waiting for OpenFAST; in the 'NREL5MW_inputs' folder, launch OpenFAST:<br />
  openfast RUN_openFAST.fst<br />
