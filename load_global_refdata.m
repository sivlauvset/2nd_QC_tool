function  load_global_refdata(ref_path,ref_name,ref_PARAM,refcruise,parameter,mindepth)

% Function to load the reference data for your secondary QC. Due to large
% amounts of data, you will most likely need to run this script twice 

% INPUT:   ref_path:    Pathway to the directory where the reference data
%                       file is stored
%          ref_name     Name of the reference data file (currently
%                       GLODAPv2_global.mat), defined in the initialization
%                       file
%          ref_PARAM:   a cell structure with the names of the parameters
%                       you want to use as reference data in the xover analysis.  
%                       NB! These names must match those in the data_PARAM and 
%                       be exactly (case sensitive) the same as the names for
%                       these parameters in the reference data file
%          refcruise:   The particular cruise to load from the ref data
%          parameter:   A number defining which of the availabel parameters
%                       you are doing a crossover analysis on
%          mindepth:    The minimum depth you want to do your crossover
%                       analysis on

% Toste Tanhua, Kiel 27.05.2009
% Modified by Siv Lauvset 2015-07-28

global param2 stat2 lat2 lon2 press2 dens2 expo2 refyr refmnth refdy

% LOAD THE REFERENCE DATA - REMEMBER TO CHANGE THE FILE NAME WHEN APPROPRIATE!!!
rfile=cat(2,[ref_path filesep ref_name]);
load(rfile)

ref_data(ref_data==-9999)=nan;

% define the availabe variables
for i=1:length(ref_vars);
     globalvar=[ref_vars{i}, ' = ref_data(:,i);'];
     eval(globalvar);
end

% Find the cruise you want to load
W=[]; expo=[];
J=find(G2cruise == refcruise);
W=[W ; J(:)];
j=find(ref_UC == refcruise);
expo2=char(ref_expocodes(j));

for i=1:length(ref_vars);
    globalvar=[ref_vars{i},' = ', ref_vars{i},'(W,:);'];
    eval(globalvar);    
end

refstat=G2station; reflat=G2latitude; refpress=G2pressure; 
refdens=sw_pden(G2salinity, G2temperature, G2pressure, 4000)-1000;

var=['param2',' = ', ref_PARAM{parameter} ';'];
eval(var); clear var

% Creates the output variables you need for the crossover analysis of this cruise
F=find(~isnan(param2) & G2pressure > mindepth); 
param2=param2(F); press2=G2pressure(F);
lat2=G2latitude(F); lon2=G2longitude(F); 
stat2=G2station(F); dens2=refdens(F);
refyr=G2year(F); refmnth=G2month(F); refdy=G2day(F);

