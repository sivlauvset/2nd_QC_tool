function varargout = run_2QC_toolbox_with_GUI(varargin)
% RUN_2QC_TOOLBOX_WITH_GUI MATLAB code for the 2QC toolbox using GUI
%
% This is a MATLAB code to start-up the 2QC GUI and initialize the 2QC toolbox
% DO NOT CHANGE ANYTHING IN THIS FILE!!! Press F5 to run on Windows or commando
% enter to run on MacOS.
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
%        PH_TMP; PH_TMP_FLAG_W; PH_TOT; PH_TOT_FLAG_W; PH; PH_FLAG_W};
% Names with a * must be included (you can choose which of the salinity parameters to include,
% but one must be in the file).  All others are optional (but you must
% of course include at least one parameter and its flags).
% The .mat file MUST be named by the cruise EXPOCODE.
%
%
% The GUI will ask for the following things:
%        1) Reference library: This is the path to the directory where you 
%        have the reference data (both the reference data product file and the
%        look-up-table for cruise numbers)
%        2) Paths to the m_map toolbox, the seawater toolbox, and the 2QC toolbox
%        When you run this function MatLab will display on the screen
%        which, if any, of these toolboxes you have to add pathways to.  If
%        nothing shows on screen you can skip this step
%        3) Minimum depth of the crossover: default is 1500 m
%        4) Maximum distance for the crossover: default is 2 degrees
%        5) Name of the data folder: This is your path to a cruise folder 
%        with one data file (.mat) inside. Note that both this folder and the 
%        data file inside it must be named by the EXPOCODE of the cruise 
%        (12 digit alphanumeric string, eg 06MS20081031).  The 2QC toolbox uses 
%        the name of this folder to name all figures and files that are 
%        generated so make sure it is correct!
%        6) Check all the parameters you want to run the 2QC toolbox for (at least one). 
%        7) Choose which surface to do the crossovers on.  Default is
%        density (i.e. sigma4) but you can also choose pressure.  Note that
%        the toolbox automatically sets the surface to pressure when doing
%        crossovers on the salinity parameters (SALNTY and CTDSAL)
%        regardless of what you choose here
%        8) After starting the program (by clicking RUN) you will be asked
%        to define your domain by clicking twice on a map.  The clicks
%        should define the top left and bottom right corners of a box
%        bounding your cruise track +/- 5 degrees.
%
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
%   8) intprofile - used by xover_2ndQC in the crossover
%   analysiscaLLmei$hmael

%   9) Xover_subplot - creates a summary figure of all offsets found during
%   the crossover analysis
%   10) posfig, xticklabel_rotate - make the figures look nicer 
% Make sure all of them are in the 2QC toolbox folder

% Siv Lauvset 2013-09-06
% last modified 2016-07-25


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @run_2QC_toolbox_with_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @run_2QC_toolbox_with_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%% --- Executes just before toolbox_path is made visible.
function run_2QC_toolbox_with_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Identify pathway to necessary toolboxes
f1=which('m_grid');
if isempty(f1)
    disp('YOU HAVE TO ADD YOUR PATH TO THE M-MAP TOOLBOX')
end
[a,b]=fileparts(f1);addpath(a);warning off
set(handles.path_1,'String',a); set(findobj('Tag','path_1'),'String',a);clear a b f1

f2=which('sw_pden');
if isempty(f2)
    disp('YOU HAVE TO ADD YOUR PATH TO THE SEAWATER TOOLBOX')
end
[a,b]=fileparts(f2);addpath(a);warning off
set(handles.path2,'String',a); set(findobj('Tag','path2'),'String',a);clear a b f2

f3=which('toolbox_2QC');
[a,b]=fileparts(f3);addpath(a);warning off
set(handles.path3,'String',a); set(findobj('Tag','path1'),'String',a);clear a b f3

f4=cd;
addpath(f4);warning off
set(handles.currentdir,'String',f4); set(findobj('Tag','currentdir'),'String',f4); clear f4

f5=which('GLODAPv2_global.mat');
if isempty(f5)
    disp('YOU HAVE TO ADD THE PATH TO WHERE THE REFERENCE DATA ARE SAVED')
else
    [refdatapath,refdataname]=fileparts(f5);
    addpath(refdatapath);
    reference_library=refdatapath
    
    handles.ref_path=refdatapath; set(findobj('Tag','ref_path'),'String',refdatapath);
    handles.ref_name=refdataname;
    % open the log file - saved to the reference directory
    fname=cat(2,[refdatapath filesep '2QC_toolbox_log.txt']);
    handles.fid=fopen(fname,'a');
end

% Set default mindepth and latlim
handles.mindepth=1500;
handles.latlim=2;
handles.surface=[1 1 1 1 1 1 2 2 1 1 2 1 1 1];
handles.Y='XoverRESULTS_DENSITY';
handles.P=zeros(1,25);

% Update handles structure
guidata(hObject, handles);

savepath

% --- Outputs from this function are returned to the command line.
function varargout = run_2QC_toolbox_with_GUI_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



%% SET THE REFERENCE DIRECTORY, ADD NECESSARY PATHWAYS, RUN THE PROGRAM
% --- Executes on button press
function ref_data_Callback(hObject, eventdata, handles)
handles.ref_path=uigetdir(''); addpath(handles.ref_path);
reference_library=(handles.ref_path)
guidata(hObject, handles);
handles.ref_name='2ndQC_ReferenceData.mat'; 
guidata(hObject, handles);
set(findobj('Tag','ref_path'),'String',handles.ref_path);

% open the log file - saved to the reference directory
fname=cat(2,[handles.ref_path filesep '2QC_toolbox_log.txt']);
handles.fid=fopen(fname,'a');
guidata(hObject, handles);

function m_map_path_Callback(hObject, eventdata, handles)
handles.f=uigetdir(''); 
m_map_toolbox=(handles.f)
addpath(handles.f)
set(findobj('Tag','path_1'),'String',handles.f);

function seawater_path_Callback(hObject, eventdata, handles)
handles.f=uigetdir('');
seawater_toolbox=(handles.f)
addpath(handles.f)
set(findobj('Tag','path2'),'String',handles.f);

function toolbox_path_Callback(hObject, eventdata, handles)
handles.f=uigetdir('');
toolbox_2QC=(handles.f)
addpath(handles.f)
set(findobj('Tag','path1'),'String',handles.f);


function run_Callback(hObject, eventdata, handles)
toolbox_2QC(handles.fid,handles.path,handles.ref_path,handles.ref_name,handles.folder,handles.mindepth,handles.latlim,handles.P,handles.surface,handles.Y)



%% CHOOSE WHICH PARAMETERS TO RUN CROSSOVER FOR
% --- Executes on button press
function tcarbn_Callback(hObject, eventdata, handles)
handles.P(1)=1;
handles.param{1}='TCARBN';
guidata(hObject, handles);

function alkali_Callback(hObject, eventdata, handles)
handles.P(2)=2;
handles.param{2}='ALKALI';
guidata(hObject, handles);

function oxygen_Callback(hObject, eventdata, handles)
handles.P(3)=3;
handles.param{3}='OXYGEN';
guidata(hObject, handles);

function phspht_Callback(hObject, eventdata, handles)
handles.P(5)=5;
handles.param{5}='PHSPHT';
guidata(hObject, handles);

function salnty_Callback(hObject, eventdata, handles)
handles.P(7)=7;
handles.param{7}='SALNTY';
guidata(hObject, handles);

function ctdoxy_Callback(hObject, eventdata, handles)
handles.P(9)=9;
handles.param{9}='CTDOXY';
guidata(hObject, handles);

function ph_Callback(hObject, eventdata, handles)
handles.P(10)=10;
handles.param{10}='PH_TOT';
guidata(hObject, handles);

function ctdsal_Callback(hObject, eventdata, handles)
handles.P(8)=8;
handles.param{8}='CTDSAL';
guidata(hObject, handles);

function silcat_Callback(hObject, eventdata, handles)
handles.P(6)=6;
handles.param{6}='SILCAT';
guidata(hObject, handles);

function nitrat_Callback(hObject, eventdata, handles)
handles.P(4)=4;
handles.param{4}='NITRAT';
guidata(hObject, handles);

function theta_Callback(hObject, eventdata, handles)
handles.P(11)=11;
handles.param{11}='THETA';
guidata(hObject, handles);

function doc_Callback(hObject, eventdata, handles)
handles.P(12)=12;
handles.param{12}='DOC';
guidata(hObject, handles);

function cfc11_Callback(hObject, eventdata, handles)
handles.P(13)=13;
handles.param{13}='CFC_11';
guidata(hObject, handles);

function cfc12_Callback(hObject, eventdata, handles)
handles.P(14)=14;
handles.param{14}='CFC_12';
guidata(hObject, handles);


%% DEFINE MINIMUM DEPTH AND MAXIMUM DISTANCE FOR CROSSOVERS
function mindepth_Callback(hObject, eventdata, handles)

handles.mindepth=str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function mindepth_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function latlim_Callback(hObject, eventdata, handles)

handles.latlim=str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function latlim_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% DEFINE THE NAME AND PATH OF FOLDER WITH DATA FILE
function folder_name_Callback(hObject, eventdata, handles)
dr=uigetdir(''); addpath(dr);
[pathstr,name]=fileparts(dr); clear dr

handles.folder=name;
handles.path=pathstr;
data_folder=(handles.folder)

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function folder_name_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% DEFINE SURFACE ON WHICH TO DO X-OVERS
% --- Executes on selection change in surface_choice.
function surface_choice_Callback(hObject, eventdata, handles)

val=get(hObject,'Value');
str=get(hObject,'String');

switch str{val}
    case 'density (i.e. sigma4)'
        handles.surface=[1 1 1 1 1 1 2 2 1 1 2 1 1 1];
        handles.Y='XoverRESULTS_DENSITY';
    case 'pressure'
        handles.surface=[2 2 2 2 2 2 2 2 2 2 2 2 2 2];
        handles.Y='XoverRESULTS_PRESSURE';
end

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function surface_choice_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function save_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file path] = uiputfile('');
print([path file], '-depsc -r600');
