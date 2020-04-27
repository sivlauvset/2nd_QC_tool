# 2nd_QC_tool
Toolbox for Secondary Quality Control (2nd QC) on ocean chemistry and hydrographic data

README FOR THE 2QC TOOLBOX
Siv Lauvset
2020-04-27

Addition 2020-03-20
The toolbox has been updated to use GLODAPv2.2019 as referene data

Addition 2015-07-28
Note that the glodapv2_csv2mat.m and cruise_overview_figure.m functions have been removed from the toolbox.


NB! PLEASE READ THIS FILE BEFORE RUNNING THE 2QC TOOLBOX!

At the top of the run_2QC_toolbox_with_GUI.m and run_2QC_toolbox_without_GUI.m there is important information about how to initialize the toolbox. 
Please follow the instructions!


Instructions for converting your data file to a .mat file:

1) Some variables have to be included in your file:  
	These are the station number (STNNBR), the position (LONGITUDE and LATITUDE), the depth/pressure at which the data was taken (CTDPRS),
	the salinity (CTDSAL or SALNTY with the respective flags) and the temperature (CTDTMP) at which the data were sampled.
	In addition you need to include at least one parameter (the one you want to do a crossover analysis for) and its associated flags.

2) The .mat file you generate MUST be named by the expocode of the cruise (a 12 digit alphanumeric string, e.g. 06MS20081031).

3) The  variables in your file MUST have the following names!  These are case sensitive!  Any other and/or additional names will not work!
The names with an * are mandatory.  NOTE: You need to include at least one salinity parameter (ctdsal or salinity) for the density calculation.

EXPOCODE
STNNBR*
CASTNO
SAMPNO
BTLNBR
BTLNBR_FLAG_W
DATE
TIME
LATITUDE*
LONGITUDE*
DEPTH
CTDPRS*
CTDTMP*
CTDSAL*
CTDSAL_FLAG_W*
SALNTY
SALNTY_FLAG_W
OXYGEN 
OXYGEN_FLAG_W
SILCAT 
SILCAT_FLAG_W
NITRAT
NITRAT_FLAG_W
PHSPHT
PHSPHT_FLAG_W
ALKALI
ALKALI_FLAG_W
TCARBN
TCARBN_FLAG_W
CTDOXY
CTDOXY_FLAG_W
any other parameters

4) You have to convert your data into a .mat file BEFORE running the 2QC toolbox.

5) If you have an exchange formatted file you can use the function excread.m which is included in the 2QC toolbox to convert your data file into a .mat file.  If your data file
is not exchange formatted the excread.m function will not work and you have to make your own routine to convert the file.  You must define the path to the seawater toolbox
before running excread.m

6) The .mat file you generate MUST be placed in a folder with the same name as the data file (i.e. the expocode of the cruise).



General information about the toolbox:

1) You can choose whether to do the crossover analysis on density levels (sigma-4) or on pressure levels.  Density is the default.
You can run the toolbox on both levels and the toolbox will automatically save the results in different folders (XoverRESULTS_DENISTY and XoverRESULTS_PRESSURE 
respectively) so that you can compare the results.

2) The toolbox automatically generates a folder, named by the minimum depth and maximum distance (Xm_Ydegrees) you define, to save the figures and Xover results in.  
This folder has subfolders named by the date when you run the toolbox so that multiple runs are saved in different folders even when the input parameters do not change 
(ie if only the flags in your data file has changed and you want to see how that affects Xover results).  NOTE:  If you rerun the toolbox on the same date then the first
results and figures will be overwritten unless you manually move them first!

3) You can choose any minimum depth and maximum distance you want but defaults are 1500 m and 2 degrees respectively.

4) DO NOT change anything in the function files. 

5) If you want to run the toolbox without a GUI you have to alter the run_2QC_toolbox_without_GUI.m script (see below).  It is clearly marked what you can (have to) change and what you cannot
change.

6) If you run the toolbox using a GUI you only have to run the run_2QC_toolbox_with_GUI.m function (F5 on Windows, commando enter on MacOS) and input what the GUI asks for.
There are instructions at the top of the run_2QC_toolbox_with_GUI.m.

7) DO NOT change anything in the run_2QC_toolbox_with_GUI.m function!

8) You will be asked to define your domain.  When the global map with your cruise track shows, click once to define the top left corner of the domain (bounding box) and once 
more to define the bottom right corner of the domain (bounding box).  These instructions are also written on the map that shows.  Note that you will not be able to click more
than twice.

9) All functions in the 2QC toolbox are written so they can run on Windox, Mac, or Linux systems without any changes.  But make sure your paths are correct and have the 
correct slashes for your OS.



Initializing the toolbox to run without using a GUI:

Open the run_2QC_toolbox_without_GUI.m file.  You will have to manually change the following in this script:

1) Paths to the m_map toolbox, the seawater toolbox, and the 2QC toolbox on your computer.
2) Path to the reference data: This is the path to the directory where the reference data set is saved (both the reference data file and the look-up-table for cruise numbers).
3) Name of the data folder: This is your path to a cruise folder with one data file (.mat) inside. Note that all cruise folders must be named by the EXPOCODE of the cruise 
it contains and the data file must have the same name as the folder (ie ALSO the EXPOCODE).  The 2QC toolbox uses the name of this folder to name all figures and files that
are generated so make sure it is correct!
4) Minimum depth of the crossover: default is 1500 m
5) Maximum distance for the crossover: default is 2 degrees
6) Choose which surface to do the crossovers on.  Default is density (i.e. sigma4) but you can also choose pressure.  Note that the toolbox automatically sets the surface 
to pressure when doing crossovers on the salinity parameters (SALNTY and CTDSAL) regardless of what you choose here
7) Write in all the parameters (at least one) you want to run the 2QC toolbox for.

Do not change anything else in the script.  Now you can run the 2QC toolbox.





Report bugs to siv.lauvset@norceresearch.no

