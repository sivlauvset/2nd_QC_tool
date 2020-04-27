
% run_2QC_toolbox_without_GUI.m
% 
% RUN_2QC_TOOLBOX_WITHOUT_GUI MATLAB code for the 2QC toolbox
%
% This is a MATLAB code to initialize the 2QC toolbox without using a GUI
%
% NB!!! READ THIS CAREFULLY!
% Before running the 2QC toolbox you have to convert your data into a
% matlab file (.mat).  This file MUST have the following variable names (case sensitive):
% NAMES={EXPOCODE; STNNBR*; CASTNO; SAMPNO; BTLNBR; BTLNBR_FLAG_W; 
%        DATE; TIME; LATITUDE*; LONGITUDE*; DEPTH; CTDPRS*; CTDTMP*;  
%        CTDSAL*;  CTDSAL_FLAG_W*; SALNTY; SALNTY_FLAG_W; OXYGEN;  
%        OXYGEN_FLAG_W; SILCAT; SILCAT_FLAG_W; NITRAT; NITRAT_FLAG_W;  
%        PHSPHT; PHSPHT_FLAG_W; ALKALI; ALKALI_FLAG_W; TCARBN; 
%        TCARBN_FLAG_W; CTDOXY; CTDOXY_FLAG_W; PH_SWS; PH_SWS_FLAG_W;  
%        PH_TMP; PH_TMP_FLAG_W; PH_TOT; PH_TOT_FLAG_W; PH; PH_FLAG_W; 
%        THETA; DOC; DOC_FLAG_W; CFC_11; CFC_11_FLAG_W; CFC_12; CFC_12_FLAG_W};
% Names with a * must be included (regarding salinities you must include 
% one - either ctd salinity or bottle salinity - in order to calculate sigma-4).  
% All others are optional (but you must of course include at least one parameter and its flags).
% The .mat file MUST be named by the cruise EXPOCODE.
% 
%
%
% Below you will have to define the following things:
%        1) Paths to the m_map toolbox, the seawater toolbox, and the 2QC toolbox
%        2) Path to the reference data: This is the path to the directory where the 
%        reference data set is saved (both the reference data file and the
%        look-up-table for cruise numbers)
%        3) Name of the data folder: This is your path to a cruise folder 
%        with one data file (.mat) inside. 
%        Note that all cruise folders must be named 
%        by the EXPOCODE of the cruise it contains and the data file must have
%        the same name as the folder (ie ALSO the EXPOCODE).  The 2QC toolbox uses 
%        the name of this folder to name all figures and files that are 
%        generated so make sure it is correct!
%        4) Minimum depth of the crossover: default is 1500 m
%        5) Maximum distance for the crossover: default is 2 degrees
%        6) Choose which surface to do the crossovers on.  Default is
%        density (i.e. sigma4) but you can also choose pressure.  Note that
%        the toolbox automatically sets the surface to pressure when doing
%        crossovers on the salinity parameters (SALNTY and CTDSAL)
%        regardless of what you choose here
%        7) Write in all the parameters (at least one) you want to run the 2QC
%        toolbox for.
%
% NB! Once the toolbox is started you will be asked to define your domain
% by clicking twice on a map.  The clicks should define the top left and
% bottom right corners of a bounding box covering your cruise track +/- 5
% degrees in all directions.
%
% This 2QC toolbox calls the following subscripts and functions:
%   1) toolbox_2QC - loads the data, removes flagged data, removes -999,
%   prepares input files for sec_QC
%   2) define_domain - creates a clickable map on which you define the
%   boundaries within which the toolbox will search for crossovers
%   3) sec_QC - identifies crossovers and make a summary offset figure
%   4) load_global_refdata - loads the data from the reference data file
%   5) xover_2ndQC - performs the crossover analysis
%   6) matching - used by xover_2ndQC in the crossover analysis
%   7) meanprofile - used by xover_2ndQC in the crossover analysis
%   8) intprofile - used by xover_2ndQC in the crossover analysis
%   9) Xover_subplot - creates a summary figure of all offsets found during
%   the crossover analysis
%   10) posfig, xticklabel_rotate - make the figures look nicer 
% Make sure all of them are in the 2QC toolbox folder

% Siv Lauvset 2013-10-21
% last modified 2015-07-28 (Siv Lauvset)
%
% Bug reports: siv.lauvset@uib.no

clear all;close all

%% USER DEFINED INPUT - CHANGE AS APPROPRIATE

% you have to add the pathway to the m-map and seawater toolboxes, as well as the 2QC toolbox
% if you have these pathways saved in your matlab search path already you
% can comment out this section or simply ignore it (in the latter case you will get a warning in your matlab command window)
addpath \matlab\m_map; warning off
addpath \matlab\seawater; warning off
addpath \2QC_toolbox; warning off

ref_path='\full\path\to\the\glodapv2\reference\dataset';

% The name of your data folder MUST be an expocode (12 digit alphanumeric
% string, eg 06MS20081031).  The data file MUST have the exact same name as
% the folder it is placed in (ie. the expocode of the cruise)

data_folder='\full\path\to\folder\with\your\datafile';  % DO NOT INCLUDE A FILE SEPARATOR ( \ OR /) AT THE END OF THE PATH!

% change the default minimum depth and maximum distance only when you have good reason to believe it is necessary
% results will be saved in a different folder if you change one or both of these
mindepth=1500;
maxdist=2;

% you can do the crossover analysis on either density surfaces (default) or on pressure surfaces
% if you know that density surfaces will not work (eg the region is very homoneneous or there are temporal trends in salinity change this to 'pressure'
% If you are unsure and want to compare results you can run the same cruise twice with different y-param and the data will be saved in different folders 
y_param='density (i.e. sigma4)';
% y_param='pressure';

% default is to run all standard parameters (TCARBN, ALKALI, OXYGEN,NITRAT, PHSPHT, SILCAT, SALNTY, CTDSAL, CTDOXY)
% if you do not want to run all, then remove those that do not apply
% DO NOT CHANGE THE VARIABLE NAMES
% DO NOT ADD VARIABLE NAMES
% param={'TCARBN', 'ALKALI', 'OXYGEN', 'NITRAT', 'PHSPHT', 'SILCAT', 'SALNTY', 'CTDSAL', 'CTDOXY','PH','THETA'};
param={'TCARBN'};

%% -----------------------------------------------------------------------
%% DO NOT CHANGE ANYTHING BELOW THIS!!!
%% -----------------------------------------------------------------------

f=which('m_grid');
[path,name]=fileparts(f); addpath(path);warning off; clear path name
if isempty(f)
    disp('YOU HAVE TO ADD YOUR PATH TO THE M-MAP TOOLBOX')
end

f=which('sw_pden');
[path,name]=fileparts(f); addpath(path);warning off; clear path name
if isempty(f)
    disp('YOU HAVE TO ADD YOUR PATH TO THE SEAWATER TOOLBOX')
end

f=which('toolbox_2QC');
[path, name]=fileparts(f); addpath(path);warning off; clear path name
if isempty(f)
    disp('YOU HAVE TO ADD YOUR PATH TO THE 2QC TOOLBOX')
end

addpath(data_folder); warning off
[path,name]=fileparts(data_folder); clear dr
folder=name;

ref_name='2ndQC_ReferenceData.mat'; 

P=zeros(1,25);
for i=1:size(param,2)
switch param{i}
    case 'TCARBN'
        P(1)=1;
    case 'ALKALI'
        P(2)=2;
    case 'OXYGEN'
        P(3)=3;
    case 'NITRAT'
        P(4)=4;
    case 'PHSPHT'
        P(5)=5;
    case 'SILCAT'
        P(6)=6;
    case 'SALNTY'
        P(7)=7;
    case 'CTDSAL'
        P(8)=8;
    case 'CTDOXY'
        P(9)=9;
    case 'PH'
        P(10)=10;
    case 'THETA'
        P(11)=11;
    case 'DOC'
        P(12)=12;
    case 'CFC_11'
        P(13)=13;
    case 'CFC_12'
        P(14)=14;
end
end

switch y_param
    case 'density (i.e. sigma4)'
        surface=[1 1 1 1 1 1 2 2 1 1 1 1 1 1];
        Y='XoverRESULTS_DENSITY';
    case 'pressure'
        surface=[2 2 2 2 2 2 2 2 2 2 2 2 2 2];
        Y='XoverRESULTS_PRESSURE';
end  

latlim=maxdist;

fname=cat(2,[ref_path filesep '2QC_toolbox_log.txt']);
fid=fopen(fname,'a');

toolbox_2QC(fid,path,ref_path,ref_name,folder,mindepth,latlim,P,surface,Y)



