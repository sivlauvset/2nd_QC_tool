function excread(cruise_folder)

% Highly modified version of exceread.m (by Steven Van Heuven), use to read
% exchange formatted oceanographic bottle data files and convert them to 
% .mat files
%
% Input: cruise_folder - This is the folder where your data file is located
%                        The name of this folder must be the expocode of
%                        the cruise (12 digit alphanumeric string, e.g. 
%                        06MS20081031)
%                        Input files are exchange formatted *.csv files
%
% Output: a .mat file named by the expocode of the cruise (i.e. the same
%         name as the folder it is inside
% 
%
% Before running a few checks have to be made:
%   1) Make sure that the names in the header of the exchange file exactly 
%   match the VARS2USE.  If there are discrepancies please change the 
%   header in the exchange file.  DO NOT change VARS2USE!
%   2) Make sure that there is at least one line (with text) before the
%   headers in the exchange file.
%   3) Remove any '' that occurs before the # in the exchange file (open
%   the file in a text reader to find such occurrances).
%   4) Read the header information in the exchange file.
%
% Are Olsen, March 2012
% modified by Siv Lauvset 2013-09-06
% modified by Siv Lauvset 2016-07-25

fclose('all');


%Define variables to read. EXPODCODE MUST BE #1 & BTLNBR #5, else change "replace -999 with NaN" loop.
VARS2USE={'EXPOCODE';'STNNBR';'CASTNO';'SAMPNO';'BTLNBR';'BTLNBR_FLAG_W';'DATE'; 'TIME';'LATITUDE'; 'LONGITUDE';...
    'DEPTH';'CTDPRS';'CTDTMP'; 'CTDSAL'; 'CTDSAL_FLAG_W';'SALNTY'; 'SALNTY_FLAG_W'; 'OXYGEN'; 'OXYGEN_FLAG_W';'SILCAT';...
    'SILCAT_FLAG_W';'NITRAT';'NITRAT_FLAG_W'; 'PHSPHT';'PHSPHT_FLAG_W'; 'ALKALI';'ALKALI_FLAG_W';'TCARBN';'TCARBN_FLAG_W';...
     'CTDOXY';'CTDOXY_FLAG_W'; 'PH_SWS';'PH_SWS_FLAG_W'; 'PH_TMP';'PH_TMP_FLAG_W'; 'PH_TOT';'PH_TOT_FLAG_W'; 'PH'; 'PH_FLAG_W'; ...
     'THETA'; 'DOC'; 'DOC_FLAG_W'; 'CFC_11'; 'CFC_11_FLAG_W'; 'CFC_12'; 'CFC_12_FLAG_W'};
%%%%%%%%%%%%%%%% END: USER DEFINED INPUT %%%%%%%%%%%%%%%%%%%%%%%


%Search for files
A=dir([cruise_folder filesep '*.csv*']);

%initialise vars
for i = 1: length(VARS2USE)
    str=cat(2,VARS2USE{i}, '=[];');
    eval(str)
end

% Load and merge the data
	file=[cruise_folder filesep A.name];
	fid=fopen(file);

    %Read line-by-line, until through header (header info is not stored)
	b=0; stillheader=1;
		while stillheader==1
		B=fgetl(fid);
		b=b+1;		
		if strcmp(B(1),'#')==0 & b>1 % Never finish on first line, which might not have '#' but clearly isn't data
			stillheader=0;
        end	
        end

   	% Read variable names
	varstart=[1 strfind(B,',')+1];
	varstop =[strfind(B,',')-1 size(B,2)];
	nov=length(varstart); % Number of variables
	variables=cell(0,0);
	
    for j = 1:nov
		variables(j,1)={B(varstart(j):varstop(j))};
	end

	% Replace incompatible characters in variable names ('-' can't be in MATLAB variable name, later on)
    % Do the same for spaces in the variable name, and for "+", "/"
	for j = 1:nov
		cv=variables{j}; % Current variable
		F=strfind(cv,'-');
		cv(F)='_';
		F=strfind(cv,' ');
		cv(F)='';
        F=strfind(cv,'+');
		cv(F)='_';
        F=strfind(cv,'/');      
		cv(F)='_';              
		variables{j}=cv;
    end
    
    % Read units
    B=fgetl(fid);
    unitstart=[1 strfind(B,',')+1];
	unitstop =[strfind(B,',')-1 size(B,2)];
	nou=length(unitstart);
	units=cell(0,0);
    
    for j = 1:nou
		units(j,1)={B(unitstart(j):unitstop(j))};
    end
    
	% Check if the variable "SECT_ID" is present (so we may ignore it)
	if strcmp(variables{2},'SECT_ID')
		sidp=1; % SectID Present
        variables(2)=[]; % Scrub it from the list
	else 
		sidp=0;
    end	

    %Find position of BTLNBR, to be read as string
    BTLNBR_index=strmatch('BTLNBR', variables, 'exact');
    
    % Read data, possibly ignoring the SECT_ID column, and allowing for different last rows.
	if sidp==1 	% If a SECT_ID column is present, ignore it
		disp('      (Variable "SECT_ID" is present, but will be ignored.)')
		string='%s%*s';
	else 
		disp('      (Variable "SECT_ID" is not present.)')
		string='%s';
    end
    
    for j = 1:nov-1
		if j==BTLNBR_index-1            %read BTLNBR as string
            string=[string '%s'];
        else
        string=[string '%f'];
        end
    end
	
    C=textscan(fid,string,'delimiter',','); % Read data using the read string

    %find last row, that has END_DATA, and remove
    index=find(strcmp('END_DATA', C{1}));
    
    for j2=1:length(C)
        C{j2}=C{j2}(1:index-1);   
    end
    
    nos=size(C{1},1);
	
    %populate VARS2USE variables
    fillNans=nan.*ones(nos,1);          %if no data, use nans

    for i2 = 1: length(VARS2USE)
        ColumnIndex=strmatch(VARS2USE{i2}, variables, 'exact');
        if isempty(ColumnIndex)                 
            str=cat(2, VARS2USE{i2}, '=[','eval(VARS2USE{i2})',';','fillNans','];');
        else
            str=cat(2, VARS2USE{i2}, '=[','eval(VARS2USE{i2})',';','C{ColumnIndex}','];');
        end
            eval(str)    
    end


% %replace -999 with NaN
 for i = [2 6:length(VARS2USE)]
     str=cat(2, 'index=find(','eval(VARS2USE{i})','==-999);');
     eval(str);
     str=cat(2, VARS2USE{i}, '(index)=NaN;');
     eval(str);
 end

%Split date
DN=datenum(num2str(DATE), 'yyyymmdd');
DS=datestr(DN,'yyyymmdd');
DAY=DS(7:8);
MONTH=DS(5:6);
YEAR=DS(1:4);

%Calculate theta, sigma
THETA=sw_ptmp(SALNTY, CTDTMP, CTDPRS, 0);
SIGMA=sw_pden(SALNTY, CTDTMP, CTDPRS, 0);
SIGMA_1=sw_pden(SALNTY, CTDTMP, CTDPRS, 1000);
SIGMA_2=sw_pden(SALNTY, CTDTMP, CTDPRS, 2000);
SIGMA_3=sw_pden(SALNTY, CTDTMP, CTDPRS, 3000);
SIGMA_4=sw_pden(SALNTY, CTDTMP, CTDPRS, 4000);


%clean up
clear A B C DN IX ColumnIndex BTLNBR_index PreCruiseNo CruiseNo F VARS2USE and b cv fid file fillNans i i2 index j j2...
    ans nos nou nov sidp stillheader str string units unitstart unitstop variables varstart varstop and tmp ...
    region n m i i2 j issub

%save
outputname=cat(2,[cruise_folder filesep cruise_folder(:,end-11:end) '.mat']); 

save(outputname,'EXPOCODE','STNNBR','CASTNO','SAMPNO','BTLNBR','BTLNBR_FLAG_W','DATE', 'TIME','LATITUDE', 'LONGITUDE',...
    'DEPTH','CTDPRS','CTDTMP', 'CTDSAL', 'CTDSAL_FLAG_W','SALNTY', 'SALNTY_FLAG_W', 'OXYGEN', 'OXYGEN_FLAG_W','SILCAT',...
    'SILCAT_FLAG_W','NITRAT','NITRAT_FLAG_W', 'PHSPHT','PHSPHT_FLAG_W', 'ALKALI','ALKALI_FLAG_W','TCARBN','TCARBN_FLAG_W',...
     'CTDOXY','CTDOXY_FLAG_W', 'PH_SWS','PH_SWS_FLAG_W', 'PH_TMP','PH_TMP_FLAG_W', 'PH_TOT','PH_TOT_FLAG_W', 'PH', 'PH_FLAG_W',...
     'THETA','DOC','DOC_FLAG_W','CFC_11','CFC_11_FLAG_W','CFC_12','CFC_12_FLAG_W')


disp('.mat file created')

