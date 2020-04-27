function toolbox_2QC(fid,PATH,ref_path,ref_name,folder,mindepth,latlim,P,surface,Y)
%
% Function to initialize the crossover analysis.  This function loads the 
% data file; removes data with flags
% other than 0, 2, and 6; and starts the 2QC analysis
%
% input: PATH     - working directory as set in GUI or defined in
%                   run_2QC_toolbox_without_GUI
%        ref_path - path to the reference data set as set in GUI or defined in
%                   run_2QC_toolbox_without_GUI
%        ref_name - name of the reference data file (currently
%                   GLODAPv2_global.mat), defined in the initialization
%                   file
%        folder   - name of the data folder as set in GUI or defined in
%                   run_2QC_toolbox_without_GUI
%        mindepth - minimum depth of crossover, can be changed in the GUI
%        latlim   - maximum distance for crossover, can be changed in the GUI
%        P        - variable set by the GUI to define which parameters are
%                   run and in which order
%        surface  - defines whether the crossovers are interpolated on
%                   density surfaces (default) or on depth/pressure surfaces
%        Y        - String determining which y-parameter you are using for the
%                   crossover analysis (used for naming folders).  Either density
%                   or pressure
%
% Siv Lauvset 2013-09-06
% last modified 2015-03-12


close all

global param ordin

ordin=surface; clear surface;

data_PARAM={'TCARBN','ALKALI','OXYGEN','NITRAT','PHSPHT','SILCAT','SALNTY','CTDSAL','CTDOXY','PH_TOT','THETA','DOC','CFC_11','CFC_12'};
ref_PARAM={'G2tco2','G2talk','G2oxygen','G2nitrate','G2phosphate','G2silicate','G2salinity','G2salinity','G2oxygen','G2phts25p0','G2theta','G2doc','G2cfc11','G2cfc12'};
param={'tco2','alk','oxygen','nitrate','phosphate','silicate','salinity','ctdsalinity','ctdoxygen','phts','theta','Doc','cfc11','cfc12'};

path=PATH;
    
    expocode=folder
    fprintf(fid,'\n %s\n',datestr(now));
    fprintf(fid,'Running 2QC toolbox for %s\n',expocode);
    
    % load data (.mat)
    load([path filesep folder filesep expocode '.mat']); 
    dta=load([path filesep folder filesep expocode '.mat']);nms=fieldnames(dta);

    % open a map where the domain in which to look for crossover cruises is defined
    [LA,LO]=define_domain(LONGITUDE,LATITUDE);
    maxlat=LA(1);minlat=LA(2);maxlon=LO(2);minlon=LO(1);
    
%     on occations there are data with flags other than 0,2,6 in the files which have to be removed here
    flaggor={'ALKALI_FLAG_W' 'CTDSAL_FLAG_W' 'NITRAT_FLAG_W' 'OXYGEN_FLAG_W' 'PHSPHT_FLAG_W'...
        'SALNTY_FLAG_W' 'SILCAT_FLAG_W' 'TCARBN_FLAG_W','CTDOXY_FLAG_W' 'PH_SWS_FLAG_W' 'PH_TOT_FLAG_W' ...
        'DOC_FLAG_W' 'CFC_11_FLAG_W' 'CFC_12_FLAG_W'};
    flagedvar={'ALKALI' 'CTDSAL' 'NITRAT' 'OXYGEN' 'PHSPHT' 'SALNTY' 'SILCAT' 'TCARBN' 'CTDOXY' 'PH_SWS' 'PH_TOT' ...
        'DOC' 'CFC_11' 'CFC_12'};
    
    for i=1:length(flaggor);
        if sum(strcmp(flaggor{i},nms))==1
        flagfind=['F = find(',flaggor{i},' ~= 2 & ', flaggor{i},' ~= 6 & ', flaggor{i}, ' ~= 0);'];
        eval(flagfind);
        flagset=[flagedvar{i},'(F) = NaN ;'];
        eval(flagset);
        end
    end
    for i=length(flagedvar)
        if sum(strcmp(flagedvar{i},nms))==1
        nanfind=['F = find(',flagedvar{i},' == -999);'];
        eval(nanfind);
        nanset=[flagedvar{i},'(F) = NaN ;'];
        eval(nanset);
        end
    end
    
    % check that the pH parameter is on the total scale at 25C
    if P(10)==10 & sum(strcmp('PH_SWS',nms))==1 
        if sum(isfinite(PH_SWS))>0
        disp('Warning: The 2QC toolbox can only do crossovers on pH on the total scale. Rescale your pH and run again.  No pH crossovers will be determined during this run.')
        fprintf(fid,'Warning: The 2QC toolbox can only do crossovers on pH on the total scale. Rescale your pH and run again.  No pH crossovers will be determined during this run.');
        P(10)=0;
        end
    end
    if P(10)==10 & sum(strcmp('PH_TOT',nms))==1
        if sum(isfinite(PH_TOT))>0
        phtmpmin=nanmin(PH_TMP(PH_TMP>-2)); phtmpmax=nanmax(PH_TMP(PH_TMP>-2)); 
            if round(nanmean([phtmpmin phtmpmax])) ~= 25
                disp('Warning: The pH (ts) in your file is not calculated for a constant temperature of 25C.  Recalculate and run again. No pH crossovers will be determined during this run.')
                fprintf(fid,'Warning: The pH (ts) in your file is not calculated for a constant temperature of 25C.  Recalculate and run again. No pH crossovers will be determined during this run.');
                P(10)=0;
            end
        else
        P(10)=0;
        end
    end
    % check whether salinity was measured on every bottle - if less than
    % 65% were measured then we have to use CTDSAL as the main salinity parameter
    if sum(strcmp('SALNTY',nms))==0
        ratio=1; % a 1 signifies that ctdsal should be used
    elseif sum(strcmp('SALNTY',nms))==1 & (length(SALNTY(isfinite(SALNTY)))/length(CTDSAL(isfinite(CTDSAL))))<0.65
        ratio=1; % a 1 signifies that ctdsal should be used
    else
        ratio=0;
    end

    % define which parameter you are working on
    for p=P
        if p==0 
            continue
        else
        var=['parameter',' = ', data_PARAM{p} ';'];
        eval(var); clear var
        if p==11
        var=['flagg',' = nan(length(parameter),1);'];
        eval(var); clear var
        else
        var=['flagg',' = ', data_PARAM{p} '_FLAG_W;'];
        eval(var); clear var
        end
       
        % identify range in the parameter to use for making the figures nicer
        parnans=parameter; parnans(parameter<-5)=nan;
        if p==4 | p==5 | p==7 | p==8 | p==10 | p==11 % nitrate, phosphate, salinities, pH, theta
        paramrng=[nanmin(parnans(CTDPRS>mindepth))-0.1 nanmax(parnans(CTDPRS>mindepth))+0.1];
        elseif p==6 | p==12 % silicate, DOC
        paramrng=[nanmin(parnans(CTDPRS>mindepth))-2 nanmax(parnans(CTDPRS>mindepth))+2];
        elseif p==13 | p==14 % CFCs
        paramrng=[nanmin(parnans(CTDPRS>mindepth))-0.25 nanmax(parnans(CTDPRS>mindepth))+0.25];
        else % tco2, alk, oxygens
        paramrng=[nanmin(parnans(CTDPRS>mindepth))-5 nanmax(parnans(CTDPRS>mindepth))+5];
        end
        clear parnans
        
        % calculate sigma-4
        if isempty(CTDSAL(isfinite(CTDSAL))) | ratio==0
            pdens=(sw_pden(SALNTY,CTDTMP,CTDPRS,4000))-1000;
        else
            pdens=(sw_pden(CTDSAL,CTDTMP,CTDPRS,4000))-1000;
        end
        % create input matrix
        input=[STNNBR LATITUDE LONGITUDE CTDPRS pdens parameter flagg]; clear parameter flagg

        % run the Xover toolbox
        sec_QC(fid,path,ref_path,ref_name,ref_PARAM,input,paramrng,folder,p,expocode,ratio,latlim,mindepth,Y,minlat,maxlat,minlon,maxlon); 
        end    
    end

clear c n m dr

fclose(fid);

