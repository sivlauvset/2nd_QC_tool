function glodap2_csv2mat(cruise_folder,datafile_name,expocode_file_name)

% Used to read the final GLODAPv2 global data product file and convert to 
% .mat files
%
% Input: cruise_folder - This is the folder where your data files are located
%        datafile_name - This is the name of the .csv file that contains
%                        all the reference data
%        expocode_file_name - This is the name of the .csv file that
%                             contains the expocodes associated with the cruise numbers in the
%                             data file
%
% Output: a .mat file with the reference data and a .mat file with the
%         lookup table used by define_domain
% 
%
%
% Siv Lauvset 2015-03-10
% last modified 2015-07-28

fclose('all');

outputfilename='2ndQC_ReferenceData';

% load data
fname=cat(2,[cruise_folder filesep datafile_name]);
G2data=csvread(fname,1,0); % skip first line which is headers
sz=size(G2data);

% load headers
fid=fopen(fname,'r');
G2headers=textscan(fid,'%s',sz(2),'delimiter',',');
G2headers=G2headers{:};

G2header=cell(size(G2headers));

% make sure headernames are correct (prefix G2 on all)
for i=1:sz(2)
    H=char(G2headers{i});
    strcheck=strcmp(H(1:2),'G2');
    if strcheck==0
        G2header{i,:}=cat(2,['G2',G2headers{i}]);
    end
    clear strcheck newname
end

% name all vars
for i=1:sz(2)
    var=[G2header{i,:}, ' = G2data(:,i);'];
    eval(var)
    clear var
end

% use only data with QC-flag=1 in the reference data
for i=1:sz(2)
    H=char(G2header{i});
    strcheck=strcmp(H(end-1:end),'qc');
    if strcheck==1 & i<53
        var=cat(2,['G2data(G2header{i,:}==0,i-2)=nan;']);
        eval(var)
        clear var
    elseif strcheck==1 & i>=53
        var=cat(2,['G2data(G2header{i,:}==0,i-3)=nan;']);
        eval(var)
        clear var
    end
    clear strcheck    
end
unique_cruises=unique(G2cruise,'stable');

% the reference data file only contains the variables we do 2QC on in the toolbox
ref_data=G2data(:,[1:18 25 27 32 37:3:49 54 58]); % save only those variables used by the 2nd QC toolbox

I=[1:18 25 27 32 37:3:49 54 58];
for i=1:length(I)
ref_vars{i,:}=G2header{I(i),:};
end
ref_vars=ref_vars';

% load expocodes
fname=[cruise_folder filesep expocode_file_name];
fid=fopen(fname);

G2expocodes=textscan(fid,'%f%s','delimiter',',','headerlines',0); 
ref_UC=G2expocodes{1};
ref_expocodes=G2expocodes{2};
    
% save as .mat file
outputname=cat(2,[cruise_folder filesep outputfilename '.mat']); 
save(outputname,'ref_data','ref_vars','unique_cruises','ref_UC','ref_expocodes');

% create lookup table for subsampling the reference dataset when running Xovers
outputname=cat(2,[cruise_folder filesep 'ReferencePositions_LookupTable.mat']);
rlat=G2latitude; rlon=G2longitude; rcruise=G2cruise;
save(outputname,'rcruise','rlat','rlon');

disp('.mat file created')


