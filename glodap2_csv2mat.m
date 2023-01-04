function glodap2_csv2mat(cruise_folder,datafile_name,expocode_file_name)

% Used to read the final GLODAPv2 global data product file and convert to 
% .mat files
%
% Input: cruise_folder - This is the folder where your data files are located
%        datafile_name - This is the name of the file (without file extension) that contains
%                        all the reference data (same filename for both the
%                        .mat and .csv files). NB! This routine loads the .mat
%                        file!
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
% last modified 2022-10-03

fclose('all');

outputfilename='2ndQC_ReferenceData';

% load headers data
fname=cat(2,[cruise_folder filesep datafile_name '.csv']);
fid=fopen(fname,'r');
G2headers=textscan(fid,'%s',109,'delimiter',',');
G2headers=G2headers{:};sz=size(G2headers);

% make sure headernames are correct (prefix G2 on all)
G2header=cell(size(G2headers));
for i=1:sz(1)
    H=char(G2headers{i});
    strcheck=strcmp(H(1:2),'G2');
    if strcheck==0
        G2header{i,:}=cat(2,['G2',G2headers{i}]);
        %---------------modified by Ilaria Stendardo 12.03.2021-------
    else
        G2header{i,:}=G2headers{i};
    end
        %--------------------------------------------------------------
    clear strcheck newname
end

% load data
G2data=load([cruise_folder filesep datafile_name '.mat']);

% define reference variables, i.e. those used in 2QC
ref_vars={'G2cruise';'G2station';'G2region';'G2cast';'G2year';'G2month';'G2day';'G2hour';'G2minute';'G2latitude';'G2longitude';'G2bottomdepth';'G2maxsampdepth';'G2bottle';'G2pressure';'G2depth';'G2temperature';'G2theta';'G2salinity';'G2salinityf';'G2salinityqc';...
    'G2sigma0';'G2sigma1';'G2sigma2';'G2sigma3';'G2sigma4';'G2gamma';'G2oxygen';'G2oxygenf';'G2oxygenqc';'G2aou';'G2aouf';'G2nitrate';'G2nitratef';'G2nitrateqc';'G2silicate';'G2silicatef';'G2silicateqc';'G2phosphate';'G2phosphatef';'G2phosphateqc';...
    'G2tco2';'G2tco2f';'G2tco2qc';'G2talk';'G2talkf';'G2talkqc';'G2fco2';'G2fco2f';'G2fco2temp';'G2phts25p0';'G2phts25p0f';'G2phtsinsitutp';'G2phtsinsitutpf';'G2phtsqc';'G2cfc11';'G2pcfc11';'G2cfc11f';'G2cfc11qc';'G2cfc12';'G2pcfc12';'G2cfc12f';'G2cfc12qc';...
    'G2cfc113';'G2pcfc113';'G2cfc113f';'G2cfc113qc';'G2ccl4';'G2pccl4';'G2ccl4f';'G2ccl4qc';'G2sf6';'G2psf6';'G2sf6f';'G2sf6qc'};

for i=1:size(ref_vars,1)
var=cat(2,['ref_data(:,i)=double(G2data.',ref_vars{i,:},');']);
eval(var)
end

% use only data with QC-flag=1 in the reference data
for i=1:size(ref_vars,1)
    H=char(ref_vars{i});
    strcheck=strcmp(H(end-1:end),'qc');
    if strcheck==1 & i<55
        %--------Modified by Ilaria Stendardo----------------
        %var=cat(2,['G2data(G2header{i,:}==0,i-2)=nan;']);
        var=cat(2,['ref_data(G2data.',ref_vars{i,:},'==0,i-2)=nan;']);
        %----------------------------------------------------
        eval(var)
        clear var
    elseif strcheck==1 & i>55
        %-----Modified by Ilaria Stendardo------------------
        %var=cat(2,['G2data(G2header{i,:}==0,i-3)=nan;']);
        var=cat(2,['ref_data(G2data.',ref_vars{i,:},'==0,i-3)=nan;']);
        %----------------------------------------------------
        eval(var)
        clear var
    elseif strcheck==1 & i==55
        var=cat(2,['ref_data(G2data.',ref_vars{i,:},'==0,i-2)=nan;']);
        eval(var)
        clear var
        var=cat(2,['ref_data(G2data.',ref_vars{i,:},'==0,i-4)=nan;']);
        eval(var)
        clear var
    end
    clear strcheck    
end
unique_cruises=unique(G2data.G2cruise,'stable');


% load expocodes
fname=[cruise_folder filesep expocode_file_name];
fid=fopen(fname);

G2expocodes=textscan(fid,'%f%s','delimiter',',','headerlines',1); 
ref_UC=G2expocodes{1};
ref_expocodes=G2expocodes{2};

% save as .mat file
outputname=cat(2,[cruise_folder filesep outputfilename '.mat']); 
save(outputname,'ref_data','ref_vars','unique_cruises','ref_UC','ref_expocodes');

% create lookup table for subsampling the reference dataset when running Xovers
outputname=cat(2,[cruise_folder filesep 'ReferencePositions_LookupTable.mat']);
rlat=G2data.G2latitude; rlon=G2data.G2longitude; rcruise=G2data.G2cruise;
save(outputname,'rcruise','rlat','rlon');

disp('.mat file created')





